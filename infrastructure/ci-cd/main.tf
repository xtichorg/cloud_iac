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
  region = var.region
}

# resource "aws_s3_bucket" "backend_bucket" {
#   bucket = var.backend_bucket_name
#   tags = {
#     Name = "backend_bucket" # Tag the S3 bucket for easier identification
#   }
# }

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"
  tags = {
    Name = "github-actions-oidc" # Tag the OIDC provider for easier identification
  }

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
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

data "aws_iam_policy_document" "s3_backend" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.backend_bucket_name}",
      "arn:aws:s3:::${var.backend_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_backend" {
  name   = "gha-s3-backend"
  policy = data.aws_iam_policy_document.s3_backend.json
}

data "aws_iam_policy_document" "terraform_infra" {
  statement {
    sid    = "AllowFullAccessForTerraformInfra"
    effect = "Allow"

    actions = [
      # IAM — создание ролей, политик, привязка ролей
      "iam:*Role*",
      "iam:*Policy*",
      "iam:PassRole",

      # EC2/VPC — сети, подсети, security groups
      "ec2:*Vpc*",
      "ec2:*Subnet*",
      "ec2:*SecurityGroup*",
      "ec2:*InternetGateway*",
      "ec2:*Route*",
      "ec2:*NatGateway*",
      "ec2:*NetworkInterface*",
      "ec2:Describe*",

      # EKS — управление кластерами
      "eks:*",

      # S3 — для remote state и артефактов
      "s3:*",

      # CloudWatch / Logs
      "logs:*",
      "cloudwatch:*",

      # Route53 — DNS, hosted zones
      "route53:*",

      # KMS — для шифрования ресурсов
      "kms:*",

      # STS — AssumeRole, если Terraform использует OIDC
      "sts:AssumeRole",
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_infra" {
  name   = "gha-terraform-infra"
  policy = data.aws_iam_policy_document.terraform_infra.json
}

resource "aws_iam_role_policy_attachment" "s3_backend_attachment" {
  policy_arn = aws_iam_policy.s3_backend.arn
  role       = aws_iam_role.github_oidc_role.name
}

resource "aws_iam_role_policy_attachment" "terraform_infra_attachment" {
  policy_arn = aws_iam_policy.terraform_infra.arn
  role       = aws_iam_role.github_oidc_role.name
}
