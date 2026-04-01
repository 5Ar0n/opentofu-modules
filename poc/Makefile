.PHONY: help localstack-start localstack-stop localstack-status localstack-logs \
        init plan apply destroy clean test-s3 test-dynamodb test-cognito \
        aws-init aws-plan aws-apply aws-destroy outputs

# Default target
help:
	@echo "HR Database Linktree - POC Infrastructure"
	@echo ""
	@echo "LocalStack Commands:"
	@echo "  make localstack-start    - Start LocalStack with Docker Compose"
	@echo "  make localstack-stop     - Stop LocalStack"
	@echo "  make localstack-status   - Check LocalStack health"
	@echo "  make localstack-logs     - View LocalStack logs"
	@echo ""
	@echo "Terraform Commands (LocalStack):"
	@echo "  make init                - Initialize Terraform"
	@echo "  make plan                - Plan infrastructure changes"
	@echo "  make apply               - Apply infrastructure changes"
	@echo "  make destroy             - Destroy infrastructure"
	@echo "  make outputs             - Show Terraform outputs"
	@echo ""
	@echo "Terraform Commands (AWS):"
	@echo "  make aws-init            - Initialize Terraform for AWS"
	@echo "  make aws-plan            - Plan AWS infrastructure changes"
	@echo "  make aws-apply           - Apply AWS infrastructure changes"
	@echo "  make aws-destroy         - Destroy AWS infrastructure"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test-s3             - Test S3 bucket"
	@echo "  make test-dynamodb       - Test DynamoDB table"
	@echo "  make test-cognito        - Test Cognito user pool"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make clean               - Clean Terraform files"

# LocalStack Management
localstack-start:
	@echo "Starting LocalStack..."
	docker-compose up -d
	@echo "Waiting for LocalStack to be ready..."
	@sleep 10
	@make localstack-status

localstack-stop:
	@echo "Stopping LocalStack..."
	docker-compose down

localstack-status:
	@echo "Checking LocalStack health..."
	@curl -s http://localhost:4566/_localstack/health | jq '.' || echo "LocalStack is not running or jq is not installed"

localstack-logs:
	docker-compose logs -f localstack

# Terraform - LocalStack
init:
	@echo "Initializing Terraform for LocalStack..."
	@if [ ! -f provider-localstack.tf ]; then \
		cp provider-localstack.tf.example provider-localstack.tf; \
		echo "Created provider-localstack.tf from example"; \
	fi
	terraform init

plan:
	@echo "Planning infrastructure changes (LocalStack)..."
	terraform plan -var-file="localstack.tfvars"

apply:
	@echo "Applying infrastructure changes (LocalStack)..."
	terraform apply -var-file="localstack.tfvars" -auto-approve
	@make outputs

destroy:
	@echo "Destroying infrastructure (LocalStack)..."
	terraform destroy -var-file="localstack.tfvars" -auto-approve

# Terraform - AWS
aws-init:
	@echo "Initializing Terraform for AWS..."
	@if [ -f provider-localstack.tf ]; then \
		mv provider-localstack.tf provider-localstack.tf.disabled; \
		echo "Disabled LocalStack provider"; \
	fi
	terraform init

aws-plan:
	@echo "Planning infrastructure changes (AWS)..."
	terraform plan

aws-apply:
	@echo "Applying infrastructure changes (AWS)..."
	terraform apply
	@make outputs

aws-destroy:
	@echo "Destroying infrastructure (AWS)..."
	@echo "WARNING: This will delete all resources in AWS!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform destroy; \
	fi

# Outputs
outputs:
	@echo ""
	@echo "=== Deployment Summary ==="
	@terraform output -json deployment_summary | jq '.' || terraform output

# Testing
test-s3:
	@echo "Testing S3 bucket..."
	@echo "<h1>HR Database Linktree - POC Test</h1>" > test-index.html
	@awslocal s3 cp test-index.html s3://hr-database-linktree-poc-local/index.html
	@awslocal s3 ls s3://hr-database-linktree-poc-local/
	@rm test-index.html
	@echo "S3 test complete!"

test-dynamodb:
	@echo "Testing DynamoDB table..."
	@awslocal dynamodb put-item \
		--table-name hr-database-poc-local \
		--item '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}, "name": {"S": "Test Employee"}, "email": {"S": "test@example.com"}}'
	@awslocal dynamodb get-item \
		--table-name hr-database-poc-local \
		--key '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}}'
	@echo "DynamoDB test complete!"

test-cognito:
	@echo "Testing Cognito user pool..."
	@USER_POOL_ID=$$(terraform output -raw cognito_user_pool_id); \
	awslocal cognito-idp admin-create-user \
		--user-pool-id $$USER_POOL_ID \
		--username test@example.com \
		--temporary-password "TempPassword123!" \
		--user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true
	@echo "Cognito test complete!"

# Cleanup
clean:
	@echo "Cleaning Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
	rm -f provider-localstack.tf
	@echo "Clean complete!"

# Quick setup for LocalStack
setup-localstack: localstack-start init apply
	@echo ""
	@echo "=== LocalStack Setup Complete ==="
	@echo "Infrastructure is ready for development!"
	@echo ""
	@echo "Run 'make test-s3' to test S3 bucket"
	@echo "Run 'make test-dynamodb' to test DynamoDB table"
	@echo "Run 'make test-cognito' to test Cognito user pool"

# Full teardown
teardown: destroy localstack-stop clean
	@echo "Full teardown complete!"
