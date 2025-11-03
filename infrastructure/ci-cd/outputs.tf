output "github_idc_provider_arn" {
  description = "The ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_oidc_role_arn" {
  description = "The ARN of the GitHub OIDC IAM role."
  value       = aws_iam_role.github_oidc_role.arn
}