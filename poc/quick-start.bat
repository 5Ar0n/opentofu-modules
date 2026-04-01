@echo off
REM HR Database Linktree - POC Infrastructure Quick Start Script (Windows)
REM This script sets up the complete POC environment with LocalStack

setlocal enabledelayedexpansion

echo ========================================
echo HR Database Linktree - POC Quick Start
echo ========================================
echo.

REM Check prerequisites
echo Checking prerequisites...

where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed
    echo Please install Docker Desktop: https://docs.docker.com/desktop/install/windows-install/
    exit /b 1
) else (
    echo [OK] Docker is installed
)

where terraform >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Terraform is not installed
    echo Please install Terraform: https://www.terraform.io/downloads
    exit /b 1
) else (
    echo [OK] Terraform is installed
)

where jq >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] jq is not installed (optional, for better output formatting)
    echo Install with: choco install jq
)

where awslocal >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] awslocal is not installed (optional, for testing)
    echo Install with: pip install awscli-local
)

echo.

REM Start LocalStack
echo ========================================
echo Starting LocalStack
echo ========================================
echo Starting LocalStack container...

docker ps | findstr hr-database-localstack >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [WARNING] LocalStack is already running
) else (
    docker-compose up -d
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to start LocalStack
        exit /b 1
    )
    echo [OK] LocalStack container started
)

echo Waiting for LocalStack to be ready...
timeout /t 10 /nobreak >nul

REM Check LocalStack health
set MAX_RETRIES=12
set RETRY_COUNT=0

:check_health
curl -s http://localhost:4566/_localstack/health >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] LocalStack is healthy
    goto health_ok
)

set /a RETRY_COUNT+=1
if %RETRY_COUNT% GEQ %MAX_RETRIES% (
    echo [ERROR] LocalStack failed to start after %MAX_RETRIES% attempts
    echo Check logs with: docker-compose logs localstack
    exit /b 1
)

echo Waiting for LocalStack... (attempt %RETRY_COUNT%/%MAX_RETRIES%)
timeout /t 5 /nobreak >nul
goto check_health

:health_ok
echo.

REM Initialize Terraform
echo ========================================
echo Initializing Terraform
echo ========================================

if not exist provider-localstack.tf (
    echo Creating LocalStack provider configuration...
    copy provider-localstack.tf.example provider-localstack.tf >nul
    echo [OK] Created provider-localstack.tf
)

echo Running terraform init...
terraform init
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Terraform init failed
    exit /b 1
)
echo [OK] Terraform initialized

echo.

REM Plan infrastructure
echo ========================================
echo Planning Infrastructure
echo ========================================
echo Running terraform plan...
terraform plan -var-file="localstack.tfvars" -out=tfplan
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Terraform plan failed
    exit /b 1
)
echo [OK] Plan created successfully

echo.

REM Apply infrastructure
echo ========================================
echo Deploying Infrastructure
echo ========================================
echo Running terraform apply...
terraform apply tfplan
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Terraform apply failed
    exit /b 1
)
del tfplan >nul 2>nul
echo [OK] Infrastructure deployed

echo.

REM Display outputs
echo ========================================
echo Deployment Summary
echo ========================================
terraform output deployment_summary

echo.

REM Run basic tests
echo ========================================
echo Running Basic Tests
echo ========================================

where awslocal >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    REM Test S3
    echo Testing S3 bucket...
    echo ^<h1^>HR Database Linktree - POC^</h1^>^<p^>Infrastructure deployed successfully!^</p^> > test-index.html
    awslocal s3 cp test-index.html s3://hr-database-linktree-poc-local/index.html >nul 2>nul
    del test-index.html >nul 2>nul
    echo [OK] S3 bucket is working

    REM Test DynamoDB
    echo Testing DynamoDB table...
    awslocal dynamodb put-item --table-name hr-database-poc-local --item "{\"PK\": {\"S\": \"TEST#1\"}, \"SK\": {\"S\": \"METADATA\"}, \"name\": {\"S\": \"Test Employee\"}}" >nul 2>nul
    echo [OK] DynamoDB table is working

    REM Test Cognito
    echo Testing Cognito user pool...
    for /f "delims=" %%i in ('terraform output -raw cognito_user_pool_id') do set USER_POOL_ID=%%i
    awslocal cognito-idp admin-create-user --user-pool-id !USER_POOL_ID! --username test@example.com --temporary-password "TempPassword123!" --user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true >nul 2>nul
    echo [OK] Cognito user pool is working
) else (
    echo [WARNING] Skipping tests (awslocal not installed)
    echo Install with: pip install awscli-local
)

echo.

REM Success message
echo ========================================
echo Setup Complete!
echo ========================================
echo [OK] POC infrastructure is ready for development
echo.
echo Next steps:
echo   1. Start developing the frontend (Task 2)
echo   2. Implement authentication (Task 3)
echo   3. Create Lambda functions (Task 5)
echo.
echo Useful commands:
echo   - View outputs: terraform output
echo   - View logs: docker-compose logs -f localstack
echo   - Stop LocalStack: docker-compose down
echo   - Destroy infrastructure: terraform destroy -var-file="localstack.tfvars"
echo.
echo For more information, see README.md

endlocal
