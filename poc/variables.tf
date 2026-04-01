# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# S3 Website Bucket
variable "website_bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
  default     = "hr-database-linktree-poc"
}

# DynamoDB Table
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "hr-database-poc"
}

# Cognito User Pool
variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "hr-database-users-poc"
}

# API Gateway
variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "hr-database-api-poc"
}

# Lambda
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "hr-database-api-poc"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment zip file"
  type        = string
  default     = "../../backend/dist/lambda.zip"
}

# Project Tags
variable "project_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "hr-database-linktree"
    Environment = "POC"
    ManagedBy   = "Terraform"
  }
}
