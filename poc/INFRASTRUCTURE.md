# POC Infrastructure Documentation

## Overview

This document provides detailed information about the POC infrastructure for the HR Database Linktree Website. The infrastructure is designed to be cost-effective (~$3.38/month on AWS) while providing all necessary services for development and validation.

## Infrastructure Components

### 1. S3 Bucket (Static Website Hosting)

**Purpose**: Host the React frontend application

**Configuration**:
- Bucket name: `hr-database-linktree-poc` (or custom)
- Versioning: Enabled
- Public access: Enabled (POC only)
- Website hosting: Enabled
  - Index document: `index.html`
  - Error document: `error.html`

**Access**:
- Public read access via bucket policy
- Direct S3 website endpoint (no CloudFront in POC)

**Cost**: ~$0.03/month (1GB storage + 10K requests)

### 2. DynamoDB Table (Database)

**Purpose**: Store employee records, service links, and history

**Configuration**:
- Table name: `hr-database-poc` (or custom)
- Billing mode: PAY_PER_REQUEST (on-demand)
- Primary key:
  - Partition key (PK): String
  - Sort key (SK): String

**Global Secondary Indexes**:

1. **DepartmentIndex**
   - Partition key: `department` (String)
   - Sort key: `name` (String)
   - Projection: ALL
   - Purpose: Efficient department-based queries

2. **SearchIndex**
   - Partition key: `status` (String)
   - Sort key: `name` (String)
   - Projection: ALL
   - Purpose: Efficient search across active employees

**Key Patterns**:

| Entity Type | PK | SK | Example |
|-------------|----|----|---------|
| Employee | `EMPLOYEE#{id}` | `METADATA` | `EMPLOYEE#123`, `METADATA` |
| Employee History | `EMPLOYEE#{id}` | `VERSION#{timestamp}` | `EMPLOYEE#123`, `VERSION#2024-01-15T10:30:00Z` |
| Service Link | `LINK` | `ORDER#{order}#ID#{id}` | `LINK`, `ORDER#0001#ID#abc` |

**Cost**: ~$1.88/month (1M reads, 500K writes)

### 3. Cognito User Pool (Authentication)

**Purpose**: Manage HR user authentication and authorization

**Configuration**:
- User pool name: `hr-database-users-poc` (or custom)
- Username: Email address
- Auto-verified: Email
- MFA: Disabled (POC only)

**Password Policy**:
- Minimum length: 12 characters
- Requires: uppercase, lowercase, numbers, symbols
- Temporary password validity: 7 days

**Token Validity**:
- Access token: 30 minutes
- ID token: 30 minutes
- Refresh token: 1 day

**Auth Flows**:
- USER_PASSWORD_AUTH
- REFRESH_TOKEN_AUTH
- USER_SRP_AUTH

**Cost**: Free tier (up to 100 MAU)

### 4. API Gateway (REST API)

**Purpose**: Provide REST API endpoints for backend operations

**Configuration**:
- API name: `hr-database-api-poc` (or custom)
- Type: REST API
- Endpoint: Regional
- Stage: `poc`

**Authorizer**:
- Type: Cognito User Pools
- Identity source: `Authorization` header
- Token validation: Automatic via Cognito

**Logging**:
- CloudWatch Logs enabled
- Log level: INFO
- Data trace: Enabled
- Metrics: Enabled
- Retention: 7 days

**CORS**:
- Will be configured per endpoint when Lambda functions are added
- Allows browser-based access from frontend

**Cost**: ~$0.35/month (100K requests)

### 5. CloudWatch Logs

**Purpose**: Store API Gateway and Lambda function logs

**Configuration**:
- Log group: `/aws/apigateway/hr-database-api-poc`
- Retention: 7 days (POC)
- Log level: INFO

**Cost**: ~$0.50/month (1GB logs)

## Data Models

### Employee Record

```json
{
  "PK": "EMPLOYEE#550e8400-e29b-41d4-a716-446655440000",
  "SK": "METADATA",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-0123",
  "position": "Software Engineer",
  "department": "Engineering",
  "hireDate": "2024-01-15",
  "status": "active",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "createdBy": "admin@example.com",
  "updatedBy": "admin@example.com",
  "version": 1
}
```

### Employee History Record

```json
{
  "PK": "EMPLOYEE#550e8400-e29b-41d4-a716-446655440000",
  "SK": "VERSION#2024-01-15T10:30:00Z",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-0123",
  "position": "Software Engineer",
  "department": "Engineering",
  "hireDate": "2024-01-15",
  "status": "active",
  "versionTimestamp": "2024-01-15T10:30:00Z",
  "changedBy": "admin@example.com",
  "changeType": "create",
  "previousVersion": 0
}
```

### Service Link Record

```json
{
  "PK": "LINK",
  "SK": "ORDER#0001#ID#abc123",
  "id": "abc123",
  "title": "Employee Portal",
  "description": "Access the main employee portal",
  "url": "https://portal.example.com",
  "order": 1,
  "enabled": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "createdBy": "admin@example.com",
  "updatedBy": "admin@example.com"
}
```

## Query Patterns

### 1. Get Employee by ID

```javascript
const params = {
  TableName: 'hr-database-poc',
  Key: {
    PK: `EMPLOYEE#${employeeId}`,
    SK: 'METADATA'
  }
};
```

### 2. Get All Employees in Department

```javascript
const params = {
  TableName: 'hr-database-poc',
  IndexName: 'DepartmentIndex',
  KeyConditionExpression: 'department = :dept',
  ExpressionAttributeValues: {
    ':dept': 'Engineering'
  }
};
```

### 3. Search Active Employees by Name

```javascript
const params = {
  TableName: 'hr-database-poc',
  IndexName: 'SearchIndex',
  KeyConditionExpression: 'status = :status AND begins_with(#name, :searchTerm)',
  ExpressionAttributeNames: {
    '#name': 'name'
  },
  ExpressionAttributeValues: {
    ':status': 'active',
    ':searchTerm': 'John'
  }
};
```

### 4. Get Employee History

```javascript
const params = {
  TableName: 'hr-database-poc',
  KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
  ExpressionAttributeValues: {
    ':pk': `EMPLOYEE#${employeeId}`,
    ':sk': 'VERSION#'
  },
  ScanIndexForward: false // Most recent first
};
```

### 5. Get All Service Links (Ordered)

```javascript
const params = {
  TableName: 'hr-database-poc',
  KeyConditionExpression: 'PK = :pk',
  ExpressionAttributeValues: {
    ':pk': 'LINK'
  },
  ScanIndexForward: true // Ascending order
};
```

## Security Considerations

### POC Environment

The POC environment prioritizes simplicity and cost-effectiveness over security:

**Acceptable for POC**:
- S3 bucket with public read access
- No MFA on Cognito
- Basic password policy only
- No WAF protection
- No encryption at rest (uses AWS defaults)
- No VPC isolation

**Not Acceptable for Production**:
- All of the above should be enhanced for production
- See production architecture in design.md

### Authentication Flow

1. User submits credentials to Cognito
2. Cognito validates and returns JWT tokens
3. Frontend includes JWT in Authorization header
4. API Gateway validates JWT with Cognito
5. If valid, request forwarded to Lambda
6. Lambda processes request and returns response

### Token Management

- Access tokens expire after 30 minutes
- Refresh tokens valid for 1 day
- Frontend should implement token refresh logic
- Session timeout warning at 25 minutes

## Monitoring and Logging

### CloudWatch Logs

**API Gateway Logs**:
- Log group: `/aws/apigateway/hr-database-api-poc`
- Includes: Request/response, errors, latency
- Retention: 7 days

**Lambda Logs** (when added):
- Log group: `/aws/lambda/{function-name}`
- Includes: Function execution, errors, custom logs
- Retention: 7 days

### Metrics

**API Gateway Metrics**:
- Request count
- Latency (p50, p95, p99)
- 4xx and 5xx errors
- Integration latency

**DynamoDB Metrics**:
- Read/write capacity units consumed
- Throttled requests
- System errors
- Conditional check failures

**Lambda Metrics** (when added):
- Invocations
- Duration
- Errors
- Throttles
- Concurrent executions

## Cost Optimization

### Current POC Costs (~$3.38/month)

| Service | Usage | Cost |
|---------|-------|------|
| S3 | 1GB storage, 10K requests | $0.03 |
| DynamoDB | 1M reads, 500K writes | $1.88 |
| API Gateway | 100K requests | $0.35 |
| Lambda | 100K invocations, 128MB | $0.62 |
| CloudWatch | 1GB logs | $0.50 |
| **Total** | | **$3.38** |

### Cost Optimization Tips

1. **Use LocalStack for Development**
   - Zero AWS costs during development
   - Faster iteration cycles
   - No cleanup required

2. **Monitor DynamoDB Usage**
   - On-demand billing charges per request
   - Consider provisioned capacity if usage is predictable
   - Use GSIs efficiently to avoid scans

3. **Optimize Lambda Functions**
   - Use appropriate memory allocation
   - Minimize cold starts
   - Reuse connections and clients

4. **Clean Up Unused Resources**
   - Delete test data regularly
   - Remove old CloudWatch logs
   - Clean up S3 bucket versions

## Deployment Checklist

### LocalStack Deployment

- [ ] Docker installed and running
- [ ] LocalStack container started
- [ ] Terraform initialized
- [ ] Infrastructure applied
- [ ] S3 bucket tested
- [ ] DynamoDB table tested
- [ ] Cognito user pool tested
- [ ] API Gateway accessible

### AWS Deployment

- [ ] AWS account configured
- [ ] Unique S3 bucket name chosen
- [ ] Terraform variables updated
- [ ] Terraform initialized
- [ ] Infrastructure planned
- [ ] Infrastructure applied
- [ ] Outputs documented
- [ ] Test user created in Cognito
- [ ] API Gateway endpoint tested
- [ ] Costs monitored

## Troubleshooting

### Common Issues

**Issue**: S3 bucket name already exists
- **Solution**: S3 bucket names are globally unique. Choose a different name in variables.

**Issue**: LocalStack not responding
- **Solution**: Check Docker container status, restart if needed, check port 4566.

**Issue**: Terraform state locked
- **Solution**: If using S3 backend, check DynamoDB lock table. Force unlock if needed.

**Issue**: API Gateway returns 403
- **Solution**: Check Cognito authorizer configuration, verify JWT token is valid.

**Issue**: DynamoDB throttling
- **Solution**: On-demand mode should auto-scale. Check for hot partitions.

### Debug Commands

```bash
# Check LocalStack health
curl http://localhost:4566/_localstack/health

# List all S3 buckets
awslocal s3 ls

# Describe DynamoDB table
awslocal dynamodb describe-table --table-name hr-database-poc-local

# List Cognito user pools
awslocal cognito-idp list-user-pools --max-results 10

# Get API Gateway details
awslocal apigateway get-rest-apis

# View CloudWatch logs
awslocal logs tail /aws/apigateway/hr-database-api-poc-local --follow
```

## Next Steps

After infrastructure is deployed:

1. **Task 2**: Initialize frontend project (React + TypeScript)
2. **Task 3**: Implement authentication components
3. **Task 5**: Create Lambda function for employee operations
4. **Task 12**: Implement service link backend operations

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
