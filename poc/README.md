# HR Database Linktree Website - POC Infrastructure

This directory contains the Terraform configuration for the POC (Proof of Concept) environment of the HR Database Linktree Website. The infrastructure is designed to work with both LocalStack (for local development) and real AWS (for cloud deployment).

## Architecture Overview

The POC environment includes:

- **S3 Bucket**: Static website hosting with public access
- **DynamoDB Table**: Single table with composite key (PK, SK) and GSIs for efficient queries
- **Cognito User Pool**: Basic authentication (no MFA) with 12-character password requirement
- **API Gateway**: REST API with Cognito authorizer
- **CloudWatch Logs**: 7-day retention for API Gateway logs

## Cost Estimate

**Monthly Cost (AWS)**: ~$3.38/month
- S3 Storage (1GB): ~$0.02
- S3 Requests (10K): ~$0.01
- Lambda Invocations (100K): ~$0.20
- Lambda Compute (128MB, 200ms avg): ~$0.42
- DynamoDB On-Demand (1M reads, 500K writes): ~$1.88
- API Gateway (100K requests): ~$0.35
- Cognito (100 MAU): Free tier
- CloudWatch Logs (1GB): ~$0.50

## Prerequisites

### For LocalStack Development

1. **Docker**: Install Docker Desktop or Docker Engine
2. **LocalStack**: Install LocalStack
   ```bash
   pip install localstack
   ```
3. **AWS CLI**: Install AWS CLI (for testing)
   ```bash
   pip install awscli-local
   ```
4. **Terraform**: Install Terraform >= 1.0
   ```bash
   # macOS
   brew install terraform
   
   # Windows
   choco install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

### For AWS Deployment

1. **AWS Account**: Active AWS account
2. **AWS CLI**: Configured with appropriate credentials
3. **Terraform**: Install Terraform >= 1.0

## Deployment Instructions

### Option 1: Deploy to LocalStack (Recommended for Development)

1. **Start LocalStack**:
   ```bash
   localstack start
   ```
   
   Or with Docker:
   ```bash
   docker run -d --name localstack -p 4566:4566 localstack/localstack
   ```

2. **Configure Terraform for LocalStack**:
   ```bash
   cd infrastructure/poc
   cp provider-localstack.tf.example provider-localstack.tf
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan -var-file="localstack.tfvars"
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply -var-file="localstack.tfvars"
   ```

6. **Verify deployment**:
   ```bash
   # List S3 buckets
   awslocal s3 ls
   
   # List DynamoDB tables
   awslocal dynamodb list-tables
   
   # List Cognito User Pools
   awslocal cognito-idp list-user-pools --max-results 10
   
   # List API Gateways
   awslocal apigateway get-rest-apis
   ```

### Option 2: Deploy to Real AWS

1. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

2. **Update variables** (optional):
   Edit `variables.tf` or create a `terraform.tfvars` file:
   ```hcl
   aws_region           = "us-east-1"
   website_bucket_name  = "your-unique-bucket-name"
   dynamodb_table_name  = "hr-database-poc"
   cognito_user_pool_name = "hr-database-users-poc"
   api_gateway_name     = "hr-database-api-poc"
   ```

3. **Initialize Terraform**:
   ```bash
   cd infrastructure/poc
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Note the outputs**:
   After successful deployment, Terraform will output important values:
   - Website URL
   - API Gateway URL
   - Cognito User Pool ID
   - Cognito Client ID
   - DynamoDB Table Name

## Infrastructure Components

### S3 Bucket Configuration

- **Purpose**: Static website hosting for React frontend
- **Access**: Public read access (POC only)
- **Features**:
  - Versioning enabled
  - Website hosting configured (index.html, error.html)
  - Public access policy

### DynamoDB Table Schema

- **Table Name**: `hr-database-poc` (or custom name)
- **Billing Mode**: PAY_PER_REQUEST (on-demand)
- **Primary Key**:
  - `PK` (String): Partition key
  - `SK` (String): Sort key
- **Global Secondary Indexes**:
  - **DepartmentIndex**: `department` (PK), `name` (SK)
  - **SearchIndex**: `status` (PK), `name` (SK)

**Key Patterns**:
- Employee: `PK=EMPLOYEE#{id}`, `SK=METADATA`
- Employee History: `PK=EMPLOYEE#{id}`, `SK=VERSION#{timestamp}`
- Service Link: `PK=LINK`, `SK=ORDER#{order}#ID#{id}`

### Cognito User Pool Configuration

- **Password Policy**:
  - Minimum 12 characters
  - Requires uppercase, lowercase, numbers, and symbols
- **Auto-verified**: Email
- **Username**: Email address
- **Token Validity**:
  - Access Token: 30 minutes
  - ID Token: 30 minutes
  - Refresh Token: 1 day
- **Auth Flows**: USER_PASSWORD_AUTH, REFRESH_TOKEN_AUTH, USER_SRP_AUTH

### API Gateway Configuration

- **Type**: REST API
- **Endpoint**: Regional
- **Authorizer**: Cognito User Pools
- **Stage**: poc
- **Logging**: Enabled (7-day retention)
- **CORS**: Will be configured per endpoint in subsequent tasks

## Testing the Infrastructure

### Test S3 Website Hosting

```bash
# Upload a test index.html
echo "<h1>HR Database Linktree - POC</h1>" > index.html

# For LocalStack
awslocal s3 cp index.html s3://hr-database-linktree-poc-local/

# For AWS
aws s3 cp index.html s3://your-bucket-name/

# Access the website
# LocalStack: http://hr-database-linktree-poc-local.s3-website.localhost.localstack.cloud:4566
# AWS: Check the website_url output from Terraform
```

### Test DynamoDB Table

```bash
# For LocalStack
awslocal dynamodb put-item \
  --table-name hr-database-poc-local \
  --item '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}, "name": {"S": "Test Employee"}}'

awslocal dynamodb get-item \
  --table-name hr-database-poc-local \
  --key '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}}'

# For AWS
aws dynamodb put-item \
  --table-name hr-database-poc \
  --item '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}, "name": {"S": "Test Employee"}}'

aws dynamodb get-item \
  --table-name hr-database-poc \
  --key '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}}'
```

### Test Cognito User Pool

```bash
# Create a test user (LocalStack)
awslocal cognito-idp admin-create-user \
  --user-pool-id <user-pool-id> \
  --username test@example.com \
  --temporary-password "TempPassword123!" \
  --user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true

# For AWS, use the same command with 'aws' instead of 'awslocal'
```

### Test API Gateway

```bash
# Get API Gateway ID
API_ID=$(terraform output -raw api_gateway_id)

# Test the API (will return 404 until endpoints are added)
curl https://${API_ID}.execute-api.us-east-1.amazonaws.com/poc/
```

## Cleanup

### LocalStack

```bash
# Destroy infrastructure
terraform destroy -var-file="localstack.tfvars"

# Stop LocalStack
localstack stop
# or
docker stop localstack
docker rm localstack
```

### AWS

```bash
# Empty S3 bucket first (required before deletion)
aws s3 rm s3://your-bucket-name --recursive

# Destroy infrastructure
terraform destroy
```

## Next Steps

After deploying the infrastructure:

1. **Task 2**: Initialize frontend project structure (React + TypeScript)
2. **Task 3**: Implement authentication components
3. **Task 5**: Create Lambda function for employee operations
4. **Task 12**: Implement service link backend operations

## Troubleshooting

### LocalStack Issues

**Problem**: LocalStack services not starting
```bash
# Check LocalStack status
localstack status

# View LocalStack logs
localstack logs

# Restart LocalStack
localstack restart
```

**Problem**: Terraform can't connect to LocalStack
- Ensure LocalStack is running: `docker ps | grep localstack`
- Check that port 4566 is accessible: `curl http://localhost:4566/_localstack/health`
- Verify provider-localstack.tf is present and configured correctly

### AWS Issues

**Problem**: S3 bucket name already exists
- S3 bucket names must be globally unique
- Update `website_bucket_name` in variables.tf or terraform.tfvars

**Problem**: Insufficient permissions
- Ensure your AWS credentials have permissions for:
  - S3 (CreateBucket, PutBucketPolicy, etc.)
  - DynamoDB (CreateTable, etc.)
  - Cognito (CreateUserPool, etc.)
  - API Gateway (CreateRestApi, etc.)
  - IAM (CreateRole, AttachRolePolicy for API Gateway logging)

## Configuration Files

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Input variables with defaults
- `outputs.tf`: Output values after deployment
- `localstack.tfvars`: LocalStack-specific variable overrides
- `provider-localstack.tf.example`: LocalStack provider configuration template

## Architecture Diagram

```
┌─────────────────┐
│   Web Browser   │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌──────────────────┐
│   S3 Bucket     │  │   API Gateway    │
│ (Static Site)   │  │   (REST API)     │
└─────────────────┘  └────────┬─────────┘
                              │
                     ┌────────┴────────┐
                     │                 │
                     ▼                 ▼
              ┌─────────────┐   ┌──────────────┐
              │   Cognito   │   │   Lambda     │
              │ (Auth)      │   │ (Functions)  │
              └─────────────┘   └──────┬───────┘
                                       │
                                       ▼
                                ┌──────────────┐
                                │  DynamoDB    │
                                │  (Database)  │
                                └──────────────┘
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
3. Review LocalStack documentation: https://docs.localstack.cloud/
4. Check the main project README for additional context

## License

This infrastructure code is part of the HR Database Linktree Website project.
