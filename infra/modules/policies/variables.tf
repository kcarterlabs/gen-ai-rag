variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vector_bucket_arn" {
  description = "ARN of the S3 vector store bucket"
  type        = string
}

variable "cost_table_arn" {
  description = "ARN of the DynamoDB cost tracking table"
  type        = string
}
