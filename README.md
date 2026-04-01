# OpenTofu Infrastructure Modules

Infrastructure as Code for the HR Database Linktree project using OpenTofu and AWS.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) v1.11+
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2
- AWS account with permissions to create: S3, DynamoDB, Cognito, API Gateway, Lambda, IAM roles, CloudWatch

## AWS Setup

### 1. Configure AWS credentials

Using SSO (recommended):
```bash
aws configure sso
aws sso login --profile <your-profile>
export AWS_PROFILE=<your-profile>
```

Or using access keys:
```bash
aws configure
```

### 2. Create the remote state backend

Before running any Tofu commands, create the S3 bucket and DynamoDB table for state management:

```bash
# S3 bucket for state storage
aws s3api create-bucket --bucket hr-database-tofu-state --region us-east-1
aws s3api put-bucket-versioning --bucket hr-database-tofu-state --versioning-configuration Status=Enabled

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name hr-database-tofu-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 3. Create the GitHub OIDC provider (for CI/CD)

If not already set up in your AWS account:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 4. Create the CI/CD IAM role

The GitHub Actions pipeline needs an IAM role with OIDC trust. Create a trust policy file:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<GITHUB_ORG>/opentofu-modules:*"
        }
      }
    }
  ]
}
```

Then create the role and attach permissions for managing all infrastructure resources (S3, DynamoDB, Cognito, API Gateway, Lambda, IAM, CloudWatch) plus the state backend (S3 bucket and DynamoDB lock table).

## Structure

```
poc/
  ├── main.tf                  # Core resources (S3, DynamoDB, Cognito, API Gateway)
  ├── lambda.tf                # Lambda function and IAM role
  ├── api-gateway-proxy.tf     # API Gateway proxy integration and CORS
  ├── api-gateway-logging.tf   # CloudWatch logging for API Gateway
  ├── backend.tf               # S3 remote state configuration
  ├── variables.tf             # Input variables
  └── outputs.tf               # Output values
```

## Usage

### Local development

```bash
cd poc
tofu init
tofu plan
tofu apply
```

### CI/CD

The pipeline runs automatically on push to `master` (for files in `poc/`):
- Runs `tofu plan` and `tofu apply` using OIDC authentication
- State is stored in S3 with DynamoDB locking
- PRs get a `tofu plan` comment

## Resources Created

| Resource | Name | Purpose |
|----------|------|---------|
| S3 Bucket | hr-database-linktree-poc | Static website hosting |
| DynamoDB Table | hr-database-poc | Single-table data store |
| Cognito User Pool | hr-database-users-poc | Authentication |
| API Gateway | hr-database-api-poc | REST API with Cognito auth |
| Lambda | hr-database-api-poc | Backend API (Node.js 20) |
| CloudWatch | /aws/lambda/hr-database-api-poc | Lambda logs (7-day retention) |
| CloudWatch | /aws/apigateway/hr-database-api-poc | API Gateway logs (7-day retention) |
