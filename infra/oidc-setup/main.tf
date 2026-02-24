# Terraform configuration to create OIDC provider and role
# This automates the manual AWS Console steps in AWS_OIDC_SETUP.md
# Run this ONCE from a local machine with AWS credentials

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

# ========================
# Variables
# ========================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "kcarterlabs"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "gen-ai-rag"
}

variable "trust_policy_mode" {
  description = "OIDC trust policy mode: 'main-only' (most secure), 'all-branches' (flexible), or 'specific-branches' (balanced)"
  type        = string
  default     = "main-only"
  
  validation {
    condition     = contains(["main-only", "all-branches", "specific-branches"], var.trust_policy_mode)
    error_message = "Trust policy mode must be one of: main-only, all-branches, specific-branches."
  }
}

variable "allowed_branches" {
  description = "List of allowed branches (only used when trust_policy_mode = 'specific-branches')"
  type        = list(string)
  default     = ["main", "develop"]
}

# ========================
# Data Sources
# ========================

data "aws_caller_identity" "current" {}

# Trust policy for main branch only (most secure)
data "aws_iam_policy_document" "github_oidc_trust_main_only" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

# Trust policy for all branches and PRs (flexible)
data "aws_iam_policy_document" "github_oidc_trust_all_branches" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

# Trust policy for specific branches (balanced)
data "aws_iam_policy_document" "github_oidc_trust_specific_branches" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = concat(
        [for branch in var.allowed_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"],
        ["repo:${var.github_org}/${var.github_repo}:pull_request"]
      )
    }
  }
}

# Select trust policy based on mode
locals {
  trust_policy = (
    var.trust_policy_mode == "main-only" ? data.aws_iam_policy_document.github_oidc_trust_main_only.json :
    var.trust_policy_mode == "all-branches" ? data.aws_iam_policy_document.github_oidc_trust_all_branches.json :
    data.aws_iam_policy_document.github_oidc_trust_specific_branches.json
  )
}

data "aws_iam_policy_document" "terraform_permissions" {
  # Lambda permissions
  statement {
    sid    = "TerraformLambda"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction",
      "lambda:PublishVersion",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy"
    ]
    resources = ["*"]
  }
  
  # S3 permissions
  statement {
    sid    = "TerraformS3"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketEncryption",
      "s3:PutBucketEncryption",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetBucketNotification",
      "s3:PutBucketNotification",
      "s3:GetBucketCORS",
      "s3:PutBucketCORS"
    ]
    resources = ["*"]
  }
  
  # DynamoDB permissions
  statement {
    sid    = "TerraformDynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:UpdateTable",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:UpdateContinuousBackups"
    ]
    resources = ["*"]
  }
  
  # API Gateway permissions
  statement {
    sid    = "TerraformAPIGateway"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE",
      "apigateway:UpdateRestApiPolicy"
    ]
    resources = ["*"]
  }
  
  # IAM permissions
  statement {
    sid    = "TerraformIAM"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:ListRoles",
      "iam:PassRole",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = ["*"]
  }
  
  # CloudWatch permissions
  statement {
    sid    = "TerraformCloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:ListTagsLogGroup",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:TagResource",
      "cloudwatch:UntagResource"
    ]
    resources = ["*"]
  }
  
  # SNS permissions
  statement {
    sid    = "TerraformSNS"
    effect = "Allow"
    actions = [
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "sns:TagResource",
      "sns:UntagResource"
    ]
    resources = ["*"]
  }
  
  # STS permissions
  statement {
    sid       = "TerraformSTSCallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

# ========================
# OIDC Provider
# ========================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
  
  tags = {
    Name        = "GitHubActions-OIDC"
    Purpose     = "GitHub Actions authentication"
    Repository  = "${var.github_org}/${var.github_repo}"
    ManagedBy   = "Terraform"
  }
}

# ========================
# IAM Role for GitHub Actions
# ========================

resource "aws_iam_role" "github_actions_terraform" {
  name               = "GitHubActionsRAGTerraformRole"
  assume_role_policy = local.trust_policy
  description        = "OIDC role for GitHub Actions to deploy RAG infrastructure via Terraform"
  max_session_duration = 3600  # 1 hour
  
  tags = {
    Name       = "GitHubActionsRAGTerraformRole"
    Purpose    = "Terraform deployment from GitHub Actions"
    Repository = "${var.github_org}/${var.github_repo}"
    ManagedBy  = "Terraform"
  }
}

# ========================
# IAM Policy for Terraform
# ========================

resource "aws_iam_policy" "github_actions_terraform" {
  name        = "GitHubActionsRAGTerraformPolicy"
  description = "Permissions for Terraform to manage RAG infrastructure"
  policy      = data.aws_iam_policy_document.terraform_permissions.json
  
  tags = {
    Name      = "GitHubActionsRAGTerraformPolicy"
    Purpose   = "Terraform permissions"
    ManagedBy = "Terraform"
  }
}

# ========================
# Attach Policy to Role
# ========================

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = aws_iam_policy.github_actions_terraform.arn
}

# ========================
# Outputs
# ========================

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions (use this as AWS_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions_terraform.arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.github_actions_terraform.name
}

output "setup_instructions" {
  description = "Next steps to complete setup"
  value       = <<-EOT
  
  ✅ OIDC Setup Complete!
  
  Trust Policy Mode: ${var.trust_policy_mode}
  ${var.trust_policy_mode == "main-only" ? "  ✅ Most secure - Only main branch can assume role" : ""}
  ${var.trust_policy_mode == "all-branches" ? "  ⚠️  Flexible - All branches and PRs can assume role (AWS will show wildcard warning)" : ""}
  ${var.trust_policy_mode == "specific-branches" ? "  ✅ Balanced - Specific branches: ${join(", ", var.allowed_branches)} + PRs" : ""}
  
  Next steps:
  
  1. Add GitHub repository secret:
     - Go to: https://github.com/${var.github_org}/${var.github_repo}/settings/secrets/actions
     - Click "New repository secret"
     - Name: AWS_ROLE_ARN
     - Value: ${aws_iam_role.github_actions_terraform.arn}
  
  2. Remove old secrets (no longer needed):
     - AWS_ACCESS_KEY_ID
     - AWS_SECRET_ACCESS_KEY
  
  3. Your GitHub Actions workflow is already configured for OIDC!
  
  4. Test the setup:
     git commit --allow-empty -m "test: verify OIDC"
     git push origin main
  
  ${var.trust_policy_mode == "main-only" ? "\n  Note: Only pushes to 'main' branch will trigger deployments.\n  Pull requests will NOT be able to run terraform plan.\n" : ""}
  EOT
}

output "trust_policy_mode" {
  description = "The trust policy mode used"
  value       = var.trust_policy_mode
}

output "allowed_sources" {
  description = "Sources allowed to assume this role"
  value = (
    var.trust_policy_mode == "main-only" ? ["main branch only"] :
    var.trust_policy_mode == "all-branches" ? ["all branches and pull requests"] :
    concat([for b in var.allowed_branches : "branch: ${b}"], ["pull requests"])
  )
}
