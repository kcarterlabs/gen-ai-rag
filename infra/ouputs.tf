# ========================
# API Gateway Outputs
# ========================

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "chat_url" {
  description = "Full URL for the chat endpoint"
  value       = module.api_gateway.chat_url
}

# ========================
# API Access Credentials
# ========================

output "api_user_name" {
  description = "IAM user for API authentication"
  value       = module.api_access.api_user_name
}

output "api_access_key_id" {
  description = "Access key ID (use AWS_ACCESS_KEY_ID)"
  value       = module.api_access.api_access_key_id
}

output "api_secret_access_key" {
  description = "Secret access key (use AWS_SECRET_ACCESS_KEY)"
  value       = module.api_access.api_secret_access_key
  sensitive   = true
}

# ========================
# Lambda Outputs
# ========================

output "chat_lambda_arn" {
  description = "ARN of the chat Lambda function"
  value       = module.lambda.chat_function_arn
}

output "ingest_lambda_arn" {
  description = "ARN of the ingest Lambda function"
  value       = module.lambda.ingest_function_arn
}

output "chat_lambda_name" {
  description = "Name of the chat Lambda function"
  value       = module.lambda.chat_function_name
}

output "ingest_lambda_name" {
  description = "Name of the ingest Lambda function"
  value       = module.lambda.ingest_function_name
}

# ========================
# Storage Outputs
# ========================

output "vector_bucket_name" {
  description = "Name of the S3 vector store bucket"
  value       = module.storage.bucket_name
}

output "vector_bucket_arn" {
  description = "ARN of the S3 vector store bucket"
  value       = module.storage.bucket_arn
}

output "upload_prefix" {
  description = "S3 prefix for uploading documents (triggers ingestion)"
  value       = local.config.s3.upload_prefix
}

# ========================
# Database Outputs
# ========================

output "cost_table_name" {
  description = "Name of the DynamoDB cost tracking table"
  value       = module.database.table_name
}

output "cost_table_arn" {
  description = "ARN of the DynamoDB cost tracking table"
  value       = module.database.table_arn
}

# ========================
# Configuration Outputs
# ========================

output "region" {
  description = "AWS region"
  value       = local.config.region
}

output "project_name" {
  description = "Project name"
  value       = local.config.project_name
}

# ========================
# Alarms Outputs
# ========================

output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  value       = module.alarms.sns_topic_arn
}

output "sns_topic_name" {
  description = "SNS topic name for alarm notifications"
  value       = module.alarms.sns_topic_name
}

output "alarm_names" {
  description = "List of all CloudWatch alarm names"
  value       = module.alarms.all_alarm_names
}
