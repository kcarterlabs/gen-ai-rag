variable "lambda_role_name" {
  description = "Name of the Lambda execution role"
  type        = string
}

variable "bedrock_policy_arn" {
  description = "ARN of the Bedrock invoke policy"
  type        = string
}

variable "s3_policy_arn" {
  description = "ARN of the S3 vector access policy"
  type        = string
}

variable "dynamodb_policy_arn" {
  description = "ARN of the DynamoDB cost access policy"
  type        = string
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
