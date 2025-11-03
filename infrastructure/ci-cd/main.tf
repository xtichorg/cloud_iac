terraform {
  required_version = "~> 1.13" # Ensure that the Terraform version is 1.0.0 or higher
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Specify the source of the AWS provider
      version = "~> 6.0"        # Use a version of the AWS provider that is compatible with version
    }
  }
}

provider "aws" {
  region = var.cicd_bucket_region
}

resource "aws_s3_bucket" "cicd" {
  bucket = var.cidi_bucket_name
  tags = {
    Name = "cicd" # Tag the S3 bucket for easier identification
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"
  tags = {
    Name = "github-actions-oidc" # Tag the OIDC provider for easier identification
  }
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.gha_oidc_assume_role_sub_values
    }
  }
}

resource "aws_iam_role" "github_oidc_role" {
  assume_role_policy   = data.aws_iam_policy_document.github_oidc_assume_role.json
  name                 = "GitHubActionsOIDCRole"
  max_session_duration = 3600
  tags = {
    Name = "GitHubActionsOIDCRole" # Tag the IAM role for easier identification
  }
}

data "aws_iam_policy_document" "s3_put" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.cidi_bucket_name}",
      "arn:aws:s3:::${var.cidi_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_put" {
  name   = "gha-s3-put"
  policy = data.aws_iam_policy_document.s3_put.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  policy_arn = aws_iam_policy.s3_put.arn
  role       = aws_iam_role.github_oidc_role.name
}
