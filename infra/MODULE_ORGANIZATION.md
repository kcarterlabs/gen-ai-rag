# Infrastructure Modules Summary

## Module Organization

The infrastructure has been refactored into modular components:

```
infra/
├── main.tf                          # Core infrastructure
├── ouputs.tf                        # Main outputs
├── config.yaml                      # Configuration
├── variables.tf                     # Variables (if any)
└── modules/
    ├── README.md                    # Module documentation
    ├── api_gateway/                 # API Gateway module
    │   ├── main.tf                 # API Gateway resources
    │   ├── variables.tf            # API Gateway inputs
    │   └── outputs.tf              # API Gateway outputs
    ├── lambda/                      # Lambda functions module
    │   ├── main.tf                 # Lambda resources
    │   ├── variables.tf            # Lambda inputs
    │   └── outputs.tf              # Lambda outputs
    └── policies/                    # IAM policies module
        ├── main.tf                 # Policy definitions
        ├── variables.tf            # Policy inputs
        └── outputs.tf              # Policy ARNs
```

## What's in Each File

### main.tf (Root)
Core AWS infrastructure:
- S3 bucket with versioning, encryption, public access block
- DynamoDB table with point-in-time recovery
- IAM role for Lambda execution
- Module invocations for policies, lambda, and API Gateway

### modules/policies/
IAM policies for:
- **Bedrock**: InvokeModel permissions for Titan and Claude
- **S3**: GetObject, PutObject, DeleteObject on vector bucket
- **DynamoDB**: PutItem, Query, GetItem on cost table

### modules/lambda/
Lambda functions:
- **Chat Lambda**: Handles user queries with RAG
- **Ingest Lambda**: Processes document uploads
- S3 event trigger for automatic ingestion
- CloudWatch log groups (7-day retention)
- Environment variables for configuration

### modules/api_gateway/
API Gateway HTTP API:
- POST /chat endpoint
- CORS configuration
- Lambda integration
- Access logging to CloudWatch
- Auto-deploy stage

## Benefits

✅ **Separation of Concerns** - Each module handles one aspect  
✅ **Reusability** - Modules can be used in multiple environments  
✅ **Maintainability** - Easier to update individual components  
✅ **Clarity** - Clean, organized code structure  
✅ **Testability** - Each module can be tested independently  

## Security Enhancements

Added to core infrastructure:
- **S3 Bucket**: Encryption at rest (AES256), versioning, block public access
- **DynamoDB**: Point-in-time recovery enabled
- **CloudWatch**: Log retention policies (7 days)
- **API Gateway**: Access logging enabled
- **Tags**: All resources tagged for management

## Deployment

The modular structure doesn't change deployment:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Or use the deployment script:

```bash
./deploy.sh
```

## Module Dependencies

```
main.tf
   ├─> modules/policies     (creates IAM policies)
   ├─> modules/lambda       (uses policies via IAM role)
   └─> modules/api_gateway  (uses Lambda invoke ARNs)
```

Dependencies are handled automatically by Terraform through module outputs/inputs.
