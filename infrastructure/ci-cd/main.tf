terraform {
  required_version = "~> 1.13" # Ensure that the Terraform version is 1.0.0 or higher
  backend "s3" {
    bucket       = "tf-state-bucket-iac"
    key          = "xtichorg/ci-cd"
    region       = "us-east-1"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Specify the source of the AWS provider
      version = "~> 6.0"        # Use a version of the AWS provider that is compatible with version
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"
  tags = {
    Name = "github-actions-oidc" # Tag the OIDC provider for easier identification
  }
}