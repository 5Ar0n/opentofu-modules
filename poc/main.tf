terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration - can be overridden for LocalStack
provider "aws" {
  region = var.aws_region

  # LocalStack configuration (uncomment for local development)
  # endpoints {
  #   s3             = "http://localhost:4566"
  #   dynamodb       = "http://localhost:4566"
  #   apigateway     = "http://localhost:4566"
  #   cognito-idp    = "http://localhost:4566"
  #   iam            = "http://localhost:4566"
  #   lambda         = "http://localhost:4566"
  #   cloudwatch     = "http://localhost:4566"
  # }
  # 
  # access_key                  = "test"
  # secret_key                  = "test"
  # skip_credentials_validation = true
  # skip_metadata_api_check     = true
  # skip_requesting_account_id  = true
}

# S3 bucket for static website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.website_bucket_name

  tags = {
    Name        = "HR Database Linktree Website"
    Environment = "POC"
    Project     = "hr-database-linktree"
  }
}

# Enable versioning for the website bucket
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Public access block configuration (allow public access for POC)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# DynamoDB table with composite key structure (PK, SK)
resource "aws_dynamodb_table" "main" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # On-demand billing for POC

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # GSI for department queries
  attribute {
    name = "department"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  # GSI for status-based queries
  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "DepartmentIndex"
    hash_key        = "department"
    range_key       = "name"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "SearchIndex"
    hash_key        = "status"
    range_key       = "name"
    projection_type = "ALL"
  }

  tags = {
    Name        = "HR Database Main Table"
    Environment = "POC"
    Project     = "hr-database-linktree"
  }
}

# Cognito User Pool with basic configuration (no MFA for POC)
resource "aws_cognito_user_pool" "main" {
  name = var.cognito_user_pool_name

  # Password policy (minimum 12 characters as per requirements)
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # Username attributes
  username_attributes = ["email"]

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Schema
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Session timeout (30 minutes as per requirements)
  # Note: This is configured in the app client

  tags = {
    Name        = "HR Database User Pool"
    Environment = "POC"
    Project     = "hr-database-linktree"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.cognito_user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Token validity (30 minutes for access token as per requirements)
  access_token_validity  = 30
  id_token_validity      = 30
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # OAuth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified"
  ]

  write_attributes = [
    "email"
  ]
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = "HR Database Linktree API - POC"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "HR Database API"
    Environment = "POC"
    Project     = "hr-database-linktree"
  }
}

# Cognito Authorizer for API Gateway
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main.arn]

  identity_source = "method.request.header.Authorization"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Force new deployment on changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.main.body,
      aws_api_gateway_authorizer.cognito.id,
      aws_api_gateway_resource.api.id,
      aws_api_gateway_resource.api_proxy.id,
      aws_api_gateway_method.api_proxy.id,
      aws_api_gateway_integration.api_proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_authorizer.cognito,
    aws_api_gateway_integration.api_proxy,
    aws_api_gateway_integration.api_proxy_options,
  ]
}

# API Gateway stage
resource "aws_api_gateway_stage" "poc" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "poc"

  tags = {
    Name        = "POC Stage"
    Environment = "POC"
    Project     = "hr-database-linktree"
  }
}

# CloudWatch Log Group for API Gateway (7-day retention for POC)
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.api_gateway_name}"
  retention_in_days = 7

  tags = {
    Name        = "API Gateway Logs"
    Environment = "POC"
    Project     = "hr-database-linktree"
  }
}

# Enable API Gateway logging
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.poc.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
  }

  depends_on = [aws_api_gateway_account.main]
}

# CORS configuration will be added to specific API Gateway resources
# when Lambda functions and endpoints are created in subsequent tasks
