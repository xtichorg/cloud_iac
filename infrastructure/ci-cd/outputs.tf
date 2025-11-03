output "github_idc_provider_arn" {
  description = "The ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}