terraform {
  backend "s3" {
    bucket         = "hr-database-tofu-state"
    key            = "poc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hr-database-tofu-locks"
    encrypt        = true
  }
}
