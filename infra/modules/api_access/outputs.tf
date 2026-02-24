output "api_user_name" {
  description = "Name of the API access IAM user"
  value       = aws_iam_user.api_user.name
}

output "api_access_key_id" {
  description = "Access key ID for API authentication"
  value       = aws_iam_access_key.api_user.id
}

output "api_secret_access_key" {
  description = "Secret access key for API authentication"
  value       = aws_iam_access_key.api_user.secret
  sensitive   = true
}
