variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "chat_lambda_invoke_arn" {
  description = "Invoke ARN of the chat Lambda function"
  type        = string
}

variable "chat_lambda_function_name" {
  description = "Name of the chat Lambda function"
  type        = string
}

variable "ingest_lambda_invoke_arn" {
  description = "Invoke ARN of the ingest Lambda function"
  type        = string
}

variable "ingest_lambda_function_name" {
  description = "Name of the ingest Lambda function"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "cors_allow_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allow_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["POST", "GET", "OPTIONS"]
}

variable "cors_allow_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["content-type", "authorization", "x-request-id"]
}

variable "cors_max_age" {
  description = "CORS max age in seconds"
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags for API Gateway resources"
  type        = map(string)
  default     = {}
}
