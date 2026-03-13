terraform {
  backend "s3" {
    bucket         = "tofu-state-585008066476"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tofu-state-locks"
    encrypt        = true
    profile        = "AdministratorAccess-585008066476"
  }
}
