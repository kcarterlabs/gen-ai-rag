# Terraform Modules

This directory contains reusable Terraform modules for the RAG GenAI infrastructure.

## Module Structure

```
modules/
├── api_gateway/          # API Gateway HTTP API configuration
│   ├── main.tf          # API Gateway, routes, integrations
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # API endpoint URLs
│
├── lambda/              # Lambda function configuration
│   ├── main.tf          # Lambda functions, CloudWatch logs, S3 triggers
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Lambda ARNs and names
│
└── policies/            # IAM policies
    ├── main.tf          # Bedrock, S3, DynamoDB policies
    ├── variables.tf     # Input variables
    └── outputs.tf       # Policy ARNs
```

## Modules Overview

### API Gateway Module

**Purpose:** Manages HTTP API Gateway for RAG endpoints

**Resources:**
- API Gateway HTTP API
- API Gateway Stage with auto-deploy
- CloudWatch log group for API access logs
- Lambda integration for /chat endpoint
- Lambda permission for API Gateway invocation

**Inputs:**
- `project_name` - Project name for resource naming
- `chat_lambda_invoke_arn` - Chat Lambda invoke ARN
- `chat_lambda_function_name` - Chat Lambda function name
- `cors_allow_origins` - CORS allowed origins (default: ["*"])
- `cors_allow_methods` - CORS allowed methods
- `cors_allow_headers` - CORS allowed headers

**Outputs:**
- `api_endpoint` - Base API endpoint URL
- `chat_url` - Full chat endpoint URL
- `api_id` - API Gateway ID
- `api_execution_arn` - API execution ARN

### Lambda Module

**Purpose:** Manages Lambda functions for chat and document ingestion

**Resources:**
- Chat Lambda function
- Ingest Lambda function
- CloudWatch log groups for both functions (7-day retention)
- S3 event trigger for ingest Lambda
- Lambda permission for S3 invocation

**Inputs:**
- `project_name` - Project name for resource naming
- `iam_role_arn` - IAM role ARN for Lambda execution
- `runtime` - Lambda runtime (default: python3.11)
- `timeout` - Lambda timeout in seconds
- `memory_size` - Lambda memory size in MB
- `deployment_package_path` - Path to lambda.zip
- `environment_variables` - Environment variables map
- `vector_bucket_id` - S3 bucket ID for event trigger
- `vector_bucket_arn` - S3 bucket ARN for permissions

**Outputs:**
- `chat_function_name` - Chat Lambda name
- `chat_function_arn` - Chat Lambda ARN
- `chat_invoke_arn` - Chat Lambda invoke ARN
- `ingest_function_name` - Ingest Lambda name
- `ingest_function_arn` - Ingest Lambda ARN
- `ingest_invoke_arn` - Ingest Lambda invoke ARN

### Policies Module

**Purpose:** Manages IAM policies for Lambda execution

**Resources:**
- Bedrock invoke policy (InvokeModel permissions)
- S3 vector access policy (GetObject, PutObject, DeleteObject)
- DynamoDB cost access policy (PutItem, Query, GetItem)

**Inputs:**
- `project_name` - Project name for resource naming
- `region` - AWS region
- `vector_bucket_arn` - S3 bucket ARN
- `cost_table_arn` - DynamoDB table ARN

**Outputs:**
- `bedrock_invoke_policy_arn` - Bedrock policy ARN
- `s3_vector_access_policy_arn` - S3 policy ARN
- `dynamodb_cost_access_policy_arn` - DynamoDB policy ARN

## Usage Example

```hcl
# Lambda module
module "lambda" {
  source = "./modules/lambda"

  project_name            = "rag-genai"
  iam_role_arn            = aws_iam_role.lambda_role.arn
  deployment_package_path = "./lambda.zip"
  
  environment_variables = {
    AWS_REGION    = "us-west-2"
    VECTOR_BUCKET = "my-vector-bucket"
    COST_TABLE    = "my-cost-table"
  }

  vector_bucket_id  = aws_s3_bucket.vector_store.id
  vector_bucket_arn = aws_s3_bucket.vector_store.arn
}

# API Gateway module
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name              = "rag-genai"
  chat_lambda_invoke_arn    = module.lambda.chat_invoke_arn
  chat_lambda_function_name = module.lambda.chat_function_name
}
```

## Benefits of Modular Structure

1. **Reusability** - Modules can be used across multiple environments
2. **Maintainability** - Easier to update and maintain isolated components
3. **Testability** - Each module can be tested independently
4. **Clarity** - Clear separation of concerns
5. **Scalability** - Easy to add new modules for new features

## Adding New Modules

To add a new module:

1. Create directory: `modules/<module-name>/`
2. Add `main.tf` with resources
3. Add `variables.tf` with inputs
4. Add `outputs.tf` with outputs
5. Reference from main infrastructure in `../main.tf`
