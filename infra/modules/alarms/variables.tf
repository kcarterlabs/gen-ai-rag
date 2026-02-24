variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "chat_lambda_name" {
  description = "Name of the chat Lambda function"
  type        = string
}

variable "ingest_lambda_name" {
  description = "Name of the ingest Lambda function"
  type        = string
}

variable "api_gateway_id" {
  description = "API Gateway ID"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "lambda_error_threshold" {
  description = "Number of Lambda errors before alarm triggers"
  type        = number
  default     = 5
}

variable "lambda_duration_threshold_ms" {
  description = "Lambda duration threshold in milliseconds (80% of timeout)"
  type        = number
  default     = 24000 # 24 seconds (80% of 30 second timeout)
}

variable "lambda_concurrent_executions_threshold" {
  description = "Maximum concurrent executions before alarm"
  type        = number
  default     = 50
}

variable "api_4xx_error_threshold" {
  description = "Number of API Gateway 4xx errors before alarm"
  type        = number
  default     = 20
}

variable "api_5xx_error_threshold" {
  description = "Number of API Gateway 5xx errors before alarm"
  type        = number
  default     = 5
}

variable "api_latency_threshold_ms" {
  description = "API Gateway latency threshold in milliseconds"
  type        = number
  default     = 5000
}

variable "enable_token_usage_alarm" {
  description = "Enable custom token usage alarm"
  type        = bool
  default     = true
}

variable "token_usage_threshold_per_hour" {
  description = "Maximum tokens per hour before alarm"
  type        = number
  default     = 1000000 # 1M tokens/hour
}

variable "enable_composite_alarm" {
  description = "Enable composite system health alarm"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for alarm resources"
  type        = map(string)
  default     = {}
}
