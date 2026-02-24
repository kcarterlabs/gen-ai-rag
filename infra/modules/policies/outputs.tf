output "bedrock_invoke_policy_arn" {
  description = "ARN of the Bedrock invoke policy"
  value       = aws_iam_policy.bedrock_invoke.arn
}

output "s3_vector_access_policy_arn" {
  description = "ARN of the S3 vector access policy"
  value       = aws_iam_policy.s3_vector_access.arn
}

output "dynamodb_cost_access_policy_arn" {
  description = "ARN of the DynamoDB cost access policy"
  value       = aws_iam_policy.dynamodb_cost_access.arn
}
