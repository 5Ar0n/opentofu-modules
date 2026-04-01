# OpenTofu Infrastructure Modules

Infrastructure as Code for the HR Database Linktree project.

## Structure

- `poc/` — POC environment (S3, DynamoDB, Cognito, API Gateway, Lambda)

## Usage

```bash
cd poc
tofu init
tofu plan
tofu apply
```

Requires AWS credentials configured via `aws configure` or SSO.
