variable "gha_oidc_assume_role_sub_values" {
  description = "List of GitHub repository sub values allowed to assume the OIDC role."
  type        = list(string)
}

variable "cidi_bucket_name" {
  description = "The name of the S3 bucket for CI/CD Terraform state."
  type        = string
}

variable "cicd_bucket_region" {
  description = "The AWS region where the CI/CD S3 bucket is located."
  type        = string
}