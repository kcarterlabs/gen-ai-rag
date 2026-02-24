# ========================
# Required Variables
# ========================

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alarm_email))
    error_message = "Must be a valid email address."
  }
}

# ========================
# Optional Variables
# ========================

variable "aws_region" {
  description = "AWS region to deploy resources (overrides config.yaml if set)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}
