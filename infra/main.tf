terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "rag-genai-terraform-state-856817629634"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "rag-genai-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = local.config.region
}

locals {
  config = yamldecode(file("${path.module}/config.yaml"))

  # Common tags applied to all resources
  common_tags = merge(
    local.config.tags,
    {
      Project = local.config.project_name
      Region  = local.config.region
    }
  )
}

# ========================
# Storage Module (S3)
# ========================

module "storage" {
  source = "./modules/storage"

  project_name         = local.config.project_name
  bucket_name          = local.config.s3.vector_bucket
  enable_versioning    = local.config.s3.enable_versioning
  encryption_algorithm = local.config.s3.encryption_algorithm
  block_public_access  = local.config.s3.block_public_access
  tags                 = local.common_tags
}

# ========================
# Database Module (DynamoDB)
# ========================

module "database" {
  source = "./modules/database"

  project_name                  = local.config.project_name
  table_name                    = local.config.dynamodb.table_name
  billing_mode                  = local.config.dynamodb.billing_mode
  hash_key                      = local.config.dynamodb.hash_key
  range_key                     = local.config.dynamodb.range_key
  enable_point_in_time_recovery = local.config.dynamodb.enable_point_in_time_recovery

  attributes = [
    {
      name = local.config.dynamodb.hash_key
      type = "S"
    },
    {
      name = local.config.dynamodb.range_key
      type = "N"
    }
  ]

  tags = local.common_tags
}

# ========================
# IAM Policies Module
# ========================

module "policies" {
  source = "./modules/policies"

  project_name      = local.config.project_name
  region            = local.config.region
  vector_bucket_arn = module.storage.bucket_arn
  cost_table_arn    = module.database.table_arn
}

# ========================
# IAM Module (Lambda Role)
# ========================

module "iam" {
  source = "./modules/iam"

  lambda_role_name    = local.config.iam.lambda_role_name
  bedrock_policy_arn  = module.policies.bedrock_invoke_policy_arn
  s3_policy_arn       = module.policies.s3_vector_access_policy_arn
  dynamodb_policy_arn = module.policies.dynamodb_cost_access_policy_arn
  tags                = local.common_tags
}

# ========================
# Lambda Functions Module
# ========================

module "lambda" {
  source = "./modules/lambda"

  project_name            = local.config.project_name
  iam_role_arn            = module.iam.lambda_role_arn
  runtime                 = local.config.lambda.runtime
  timeout                 = local.config.lambda.timeout
  memory_size             = local.config.lambda.memory
  log_retention_days      = local.config.lambda.log_retention_days
  deployment_package_path = "${path.module}/lambda.zip"

  environment_variables = {
    VECTOR_BUCKET = module.storage.bucket_name
    COST_TABLE    = module.database.table_name
  }

  vector_bucket_id  = module.storage.bucket_id
  vector_bucket_arn = module.storage.bucket_arn

  tags = local.common_tags
}

# ========================
# API Gateway Module
# ========================

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name              = local.config.project_name
  chat_lambda_invoke_arn    = module.lambda.chat_invoke_arn
  chat_lambda_function_name = module.lambda.chat_function_name
  log_retention_days        = local.config.api_gateway.log_retention_days

  cors_allow_origins = local.config.api_gateway.cors.allow_origins
  cors_allow_methods = local.config.api_gateway.cors.allow_methods
  cors_allow_headers = local.config.api_gateway.cors.allow_headers
  cors_max_age       = local.config.api_gateway.cors.max_age

  tags = local.common_tags
}

# ========================
# CloudWatch Alarms Module
# ========================

module "alarms" {
  source = "./modules/alarms"

  project_name        = local.config.project_name
  chat_lambda_name    = module.lambda.chat_function_name
  ingest_lambda_name  = module.lambda.ingest_function_name
  api_gateway_id      = module.api_gateway.api_id
  dynamodb_table_name = module.database.table_name

  alarm_email                            = var.alarm_email
  lambda_error_threshold                 = local.config.alarms.lambda_error_threshold
  lambda_duration_threshold_ms           = local.config.alarms.lambda_duration_threshold_ms
  lambda_concurrent_executions_threshold = local.config.alarms.lambda_concurrent_executions_threshold
  api_4xx_error_threshold                = local.config.alarms.api_4xx_error_threshold
  api_5xx_error_threshold                = local.config.alarms.api_5xx_error_threshold
  api_latency_threshold_ms               = local.config.alarms.api_latency_threshold_ms
  token_usage_threshold_per_hour         = local.config.alarms.token_usage_threshold_per_hour
  enable_token_usage_alarm               = local.config.alarms.enable_token_usage_alarm
  enable_composite_alarm                 = local.config.alarms.enable_composite_alarm

  tags = local.common_tags
}
