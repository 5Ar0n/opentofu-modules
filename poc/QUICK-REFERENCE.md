# Quick Reference Card

## 🚀 Quick Start

### LocalStack (Development)
```bash
# Start everything
make setup-localstack

# Or manually
docker-compose up -d
terraform init
terraform apply -var-file="localstack.tfvars"
```

### AWS (Cloud)
```bash
# Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

# Deploy
terraform init
terraform apply
```

## 📋 Common Commands

### LocalStack Management
```bash
make localstack-start    # Start LocalStack
make localstack-stop     # Stop LocalStack
make localstack-status   # Check health
make localstack-logs     # View logs
```

### Terraform Operations
```bash
make init                # Initialize (LocalStack)
make plan                # Plan changes
make apply               # Deploy infrastructure
make destroy             # Destroy infrastructure
make outputs             # Show outputs

make aws-init            # Initialize (AWS)
make aws-apply           # Deploy to AWS
make aws-destroy         # Destroy AWS resources
```

### Testing
```bash
make test-s3             # Test S3 bucket
make test-dynamodb       # Test DynamoDB
make test-cognito        # Test Cognito
```

## 🔑 Key Outputs

After deployment, get these values:
```bash
terraform output website_url              # Frontend URL
terraform output api_gateway_invoke_url   # API endpoint
terraform output cognito_user_pool_id     # User pool ID
terraform output cognito_client_id        # Client ID
terraform output dynamodb_table_name      # Table name
```

## 📊 DynamoDB Key Patterns

| Entity | PK | SK |
|--------|----|----|
| Employee | `EMPLOYEE#{id}` | `METADATA` |
| History | `EMPLOYEE#{id}` | `VERSION#{timestamp}` |
| Link | `LINK` | `ORDER#{order}#ID#{id}` |

## 🔐 Cognito Configuration

- **Username**: Email address
- **Password**: Min 12 chars, uppercase, lowercase, number, symbol
- **Token validity**: 30 minutes
- **MFA**: Disabled (POC)

## 🌐 API Gateway

- **Stage**: poc
- **Authorizer**: Cognito User Pools
- **Auth header**: `Authorization: Bearer {token}`

## 💰 Cost Estimate

**POC**: ~$3.38/month
- S3: $0.03
- DynamoDB: $1.88
- API Gateway: $0.35
- Lambda: $0.62
- CloudWatch: $0.50

**LocalStack**: $0 (free)

## 🧪 Testing Commands

### S3
```bash
# LocalStack
awslocal s3 ls
awslocal s3 cp file.html s3://hr-database-linktree-poc-local/

# AWS
aws s3 ls s3://your-bucket-name/
aws s3 cp file.html s3://your-bucket-name/
```

### DynamoDB
```bash
# LocalStack
awslocal dynamodb list-tables
awslocal dynamodb put-item --table-name hr-database-poc-local \
  --item '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}}'

# AWS
aws dynamodb list-tables
aws dynamodb put-item --table-name hr-database-poc \
  --item '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}}'
```

### Cognito
```bash
# LocalStack
awslocal cognito-idp list-user-pools --max-results 10

# AWS
aws cognito-idp list-user-pools --max-results 10
```

## 🐛 Troubleshooting

### LocalStack not starting
```bash
docker ps                          # Check container
docker-compose logs localstack     # View logs
docker-compose restart             # Restart
```

### Terraform errors
```bash
terraform fmt                      # Format files
terraform validate                 # Validate config
terraform init -upgrade            # Upgrade providers
```

### AWS credentials
```bash
aws configure                      # Configure credentials
aws sts get-caller-identity        # Verify credentials
```

## 📁 File Structure

```
infrastructure/poc/
├── main.tf                    # Infrastructure
├── variables.tf               # Variables
├── outputs.tf                 # Outputs
├── docker-compose.yml         # LocalStack
├── Makefile                   # Commands
├── README.md                  # Full guide
└── INFRASTRUCTURE.md          # Details
```

## 🔗 Useful Links

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [LocalStack Docs](https://docs.localstack.cloud/)
- [AWS S3 Docs](https://docs.aws.amazon.com/s3/)
- [AWS DynamoDB Docs](https://docs.aws.amazon.com/dynamodb/)
- [AWS Cognito Docs](https://docs.aws.amazon.com/cognito/)
- [AWS API Gateway Docs](https://docs.aws.amazon.com/apigateway/)

## 📞 Support

1. Check README.md
2. Check INFRASTRUCTURE.md
3. Review error logs
4. Check AWS/LocalStack documentation

## ✅ Deployment Checklist

### LocalStack
- [ ] Docker running
- [ ] LocalStack started
- [ ] Terraform initialized
- [ ] Infrastructure applied
- [ ] Tests passing

### AWS
- [ ] AWS credentials configured
- [ ] Unique bucket name chosen
- [ ] Variables updated
- [ ] Terraform initialized
- [ ] Infrastructure applied
- [ ] Outputs documented
- [ ] Costs monitored

## 🎯 Next Steps

1. Task 2: Initialize frontend (React + TypeScript)
2. Task 3: Implement authentication
3. Task 5: Create Lambda functions
4. Task 12: Implement service links

---

**Quick Help**: Run `make help` for all available commands
