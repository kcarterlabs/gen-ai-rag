variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "api_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
