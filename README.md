# OpenTofu Infrastructure Modules

OpenTofu modules for managing AWS infrastructure.

## Prerequisites

- OpenTofu installed
- AWS CLI configured with SSO
- GitHub Actions OIDC configured

## Setup

This repository includes the foundational infrastructure:

- **S3 Backend**: `tofu-state-585008066476`
- **DynamoDB Lock Table**: `tofu-state-locks`
- **GitHub OIDC Provider**: Configured for GitHub Actions
- **IAM Role**: `github-actions-role` for CI/CD

## Usage

### Local Development

1. Login to AWS SSO:
```bash
aws sso login --profile AdministratorAccess-585008066476
```

2. Initialize OpenTofu:
```bash
tofu init
```

3. Plan changes:
```bash
tofu plan
```

4. Apply changes:
```bash
tofu apply
```

### GitHub Actions

The repository includes a GitHub Actions workflow that automatically:
- Runs `tofu plan` on pull requests
- Runs `tofu apply` on pushes to main branch
- Uses OIDC for secure AWS authentication (no access keys needed)

## Infrastructure

- **Region**: us-east-1
- **Account**: 585008066476
- **State Storage**: S3 with versioning and encryption
- **State Locking**: DynamoDB

## GitHub Actions Role

ARN: `arn:aws:iam::585008066476:role/github-actions-role`

This role has AdministratorAccess and is configured to trust GitHub Actions from repositories under the `5Ar0n` account.
