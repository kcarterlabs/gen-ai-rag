variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "deployment_package_path" {
  description = "Path to Lambda deployment package"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for Lambda functions"
  type        = map(string)
  default     = {}
}

variable "vector_bucket_id" {
  description = "S3 vector bucket ID for event trigger"
  type        = string
}

variable "vector_bucket_arn" {
  description = "S3 vector bucket ARN for permissions"
  type        = string
}

variable "tags" {
  description = "Additional tags for Lambda functions"
  type        = map(string)
  default     = {}
}
