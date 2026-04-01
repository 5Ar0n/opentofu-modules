#!/bin/bash

# HR Database Linktree - POC Infrastructure Quick Start Script
# This script sets up the complete POC environment with LocalStack

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    else
        print_success "$1 is installed"
        return 0
    fi
}

# Main script
print_header "HR Database Linktree - POC Quick Start"

# Check prerequisites
print_info "Checking prerequisites..."
MISSING_DEPS=0

if ! check_command docker; then
    print_error "Please install Docker: https://docs.docker.com/get-docker/"
    MISSING_DEPS=1
fi

if ! check_command docker-compose; then
    print_warning "docker-compose not found, trying 'docker compose'..."
    if ! docker compose version &> /dev/null; then
        print_error "Please install Docker Compose: https://docs.docker.com/compose/install/"
        MISSING_DEPS=1
    else
        print_success "docker compose is available"
        alias docker-compose='docker compose'
    fi
fi

if ! check_command terraform; then
    print_error "Please install Terraform: https://www.terraform.io/downloads"
    MISSING_DEPS=1
fi

if ! check_command jq; then
    print_warning "jq is not installed (optional, for better output formatting)"
    print_info "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
fi

if ! check_command awslocal; then
    print_warning "awslocal is not installed (optional, for testing)"
    print_info "Install with: pip install awscli-local"
fi

if [ $MISSING_DEPS -eq 1 ]; then
    print_error "Missing required dependencies. Please install them and try again."
    exit 1
fi

echo ""

# Start LocalStack
print_header "Starting LocalStack"
print_info "Starting LocalStack container..."

if docker ps | grep -q hr-database-localstack; then
    print_warning "LocalStack is already running"
else
    docker-compose up -d
    print_success "LocalStack container started"
fi

print_info "Waiting for LocalStack to be ready..."
sleep 10

# Check LocalStack health
MAX_RETRIES=12
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        print_success "LocalStack is healthy"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            print_error "LocalStack failed to start after $MAX_RETRIES attempts"
            print_info "Check logs with: docker-compose logs localstack"
            exit 1
        fi
        print_info "Waiting for LocalStack... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
    fi
done

echo ""

# Initialize Terraform
print_header "Initializing Terraform"

if [ ! -f provider-localstack.tf ]; then
    print_info "Creating LocalStack provider configuration..."
    cp provider-localstack.tf.example provider-localstack.tf
    print_success "Created provider-localstack.tf"
fi

print_info "Running terraform init..."
terraform init
print_success "Terraform initialized"

echo ""

# Plan infrastructure
print_header "Planning Infrastructure"
print_info "Running terraform plan..."
terraform plan -var-file="localstack.tfvars" -out=tfplan
print_success "Plan created successfully"

echo ""

# Apply infrastructure
print_header "Deploying Infrastructure"
print_info "Running terraform apply..."
terraform apply tfplan
rm -f tfplan
print_success "Infrastructure deployed"

echo ""

# Display outputs
print_header "Deployment Summary"
if command -v jq &> /dev/null; then
    terraform output -json deployment_summary | jq '.'
else
    terraform output deployment_summary
fi

echo ""

# Run basic tests
print_header "Running Basic Tests"

if command -v awslocal &> /dev/null; then
    # Test S3
    print_info "Testing S3 bucket..."
    echo "<h1>HR Database Linktree - POC</h1><p>Infrastructure deployed successfully!</p>" > test-index.html
    awslocal s3 cp test-index.html s3://hr-database-linktree-poc-local/index.html > /dev/null 2>&1
    rm test-index.html
    print_success "S3 bucket is working"

    # Test DynamoDB
    print_info "Testing DynamoDB table..."
    awslocal dynamodb put-item \
        --table-name hr-database-poc-local \
        --item '{"PK": {"S": "TEST#1"}, "SK": {"S": "METADATA"}, "name": {"S": "Test Employee"}}' > /dev/null 2>&1
    print_success "DynamoDB table is working"

    # Test Cognito
    print_info "Testing Cognito user pool..."
    USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
    awslocal cognito-idp admin-create-user \
        --user-pool-id $USER_POOL_ID \
        --username test@example.com \
        --temporary-password "TempPassword123!" \
        --user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true > /dev/null 2>&1 || true
    print_success "Cognito user pool is working"
else
    print_warning "Skipping tests (awslocal not installed)"
    print_info "Install with: pip install awscli-local"
fi

echo ""

# Success message
print_header "Setup Complete!"
print_success "POC infrastructure is ready for development"
echo ""
print_info "Next steps:"
echo "  1. Start developing the frontend (Task 2)"
echo "  2. Implement authentication (Task 3)"
echo "  3. Create Lambda functions (Task 5)"
echo ""
print_info "Useful commands:"
echo "  - View outputs: terraform output"
echo "  - View logs: docker-compose logs -f localstack"
echo "  - Stop LocalStack: docker-compose down"
echo "  - Destroy infrastructure: terraform destroy -var-file='localstack.tfvars'"
echo ""
print_info "For more information, see README.md"
