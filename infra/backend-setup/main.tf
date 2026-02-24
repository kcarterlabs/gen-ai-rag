# Terraform Backend Setup
# Run this ONCE before deploying main infrastructure
# This creates the S3 bucket and DynamoDB table for remote state

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "rag-genai"
}

variable "account_id" {
  description = "AWS account ID (for bucket naming)"
  type        = string
}

locals {
  state_bucket = "${var.project_name}-terraform-state-${var.account_id}"
  lock_table   = "${var.project_name}-terraform-locks"
}

# ========================
# S3 Bucket for State
# ========================

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = local.state_bucket
    Purpose   = "terraform-state"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Enable versioning to track state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable lifecycle policy to manage old versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ========================
# DynamoDB Table for Locking
# ========================

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = local.lock_table
    Purpose   = "terraform-state-locking"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ========================
# Outputs
# ========================

output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "backend_configuration" {
  description = "Backend configuration to add to main.tf"
  value       = <<-EOT
  
  Add this to infra/main.tf:
  
  terraform {
    backend "s3" {
      bucket         = "${local.state_bucket}"
      key            = "terraform.tfstate"
      region         = "${var.aws_region}"
      dynamodb_table = "${local.lock_table}"
      encrypt        = true
    }
  }
  
  Then run: terraform init -migrate-state
  
  EOT
}

output "next_steps" {
  description = "What to do after running this"
  value       = <<-EOT
  
  ✅ Remote State Setup Complete!
  
  State Bucket: ${local.state_bucket}
  Lock Table:   ${local.lock_table}
  
  Next steps:
  
  1. Update infra/main.tf with backend configuration (see output above)
  
  2. Initialize backend:
     cd ../
     terraform init -migrate-state
  
  3. Commit and push backend configuration
  
  4. GitHub Actions will now use remote state automatically
  
  Cost: ~$0.05/month (S3 storage + DynamoDB on-demand)
  
  EOT
}
