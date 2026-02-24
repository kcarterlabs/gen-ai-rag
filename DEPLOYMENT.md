# Infrastructure Setup - Quick Reference

## What Was Added

### 1. IAM Policies Module (`infra/modules/policies/`)
- **Bedrock permissions**: Invoke Titan embeddings and Claude chat models
- **S3 permissions**: Read/write/delete vectors in the bucket
- **DynamoDB permissions**: PutItem, Query, GetItem for cost tracking

### 2. Lambda Functions
- **Chat Lambda**: Handles user queries with RAG
  - Environment variables: AWS_REGION, VECTOR_BUCKET, COST_TABLE
- **Ingest Lambda**: Processes uploaded documents
  - Triggered by S3 uploads to `uploads/` prefix

### 3. API Gateway HTTP API
- **POST /chat**: Query endpoint
- **CORS enabled**: For frontend integration
- **Auto-deploy**: Immediate deployment of changes

### 4. S3 Event Trigger
- Uploads to `s3://bucket/uploads/*` trigger the ingest Lambda
- Automatically processes new documents

---

## Deployment

### Prerequisites
```bash
# Install AWS CLI and configure credentials
aws configure

# Install Terraform
# Download from: https://www.terraform.io/downloads
```

### Deploy Everything
```bash
./deploy.sh
```

This script will:
1. Package all Python code into `lambda.zip`
2. Install dependencies (currently just boto3)
3. Run `terraform plan`
4. Ask for confirmation
5. Deploy infrastructure
6. Show API endpoint and other outputs

### Manual Deployment
```bash
# Package Lambda code
cd /home/kenny/rag-genai
pip install -r requirements.txt -t build/
cp *.py build/
cd build && zip -r ../infra/lambda.zip . && cd ..
rm -rf build

# Deploy with Terraform
cd infra
terraform init
terraform plan
terraform apply
```

---

## Testing After Deployment

### 1. Get API Endpoint
```bash
cd infra
terraform output chat_url
```

### 2. Test Chat (will return placeholder data initially)
```bash
CHAT_URL=$(cd infra && terraform output -raw chat_url)

curl -X POST $CHAT_URL \
  -H "Content-Type: application/json" \
  -d '{"question": "What is machine learning?"}'
```

### 3. Upload a Document to Ingest
```bash
BUCKET=$(cd infra && terraform output -raw vector_bucket_name)

# Create a test document
cat > test-doc.txt << EOF
Machine learning is a subset of artificial intelligence that focuses on 
building systems that learn from data. Deep learning uses neural networks 
with multiple layers to learn complex patterns.
EOF

# Upload to trigger ingestion
aws s3 cp test-doc.txt s3://$BUCKET/uploads/test-doc.txt

# Check Lambda logs
aws logs tail /aws/lambda/rag-genai-ingest --follow
```

### 4. Check Cost Tracking
```bash
TABLE=$(cd infra && terraform output -raw cost_table_name)

aws dynamodb scan --table-name $TABLE
```

---

## Infrastructure Resources Created

- **S3 Bucket**: `rag-genai-vectors` - Stores vector embeddings
- **DynamoDB Table**: `rag-genai-costs` - Tracks API costs
- **2 Lambda Functions**: Chat and Ingest handlers
- **API Gateway**: HTTP API with /chat endpoint
- **IAM Role + Policies**: Scoped permissions for Bedrock, S3, DynamoDB

---

## Architecture Flow

### Document Ingestion
```
User uploads file to S3 (uploads/ prefix)
    ↓
S3 triggers Ingest Lambda
    ↓
Lambda chunks document
    ↓
Calls Bedrock for embeddings
    ↓
Stores vectors in S3
    ↓
Logs costs to DynamoDB
```

### Chat Query
```
User sends POST to /chat endpoint
    ↓
API Gateway invokes Chat Lambda
    ↓
Lambda generates query embedding
    ↓
Retrieves similar chunks from S3
    ↓
Calls Bedrock for chat completion
    ↓
Returns answer to user
    ↓
Logs costs to DynamoDB
```

---

## Cost Estimates

Based on AWS pricing (as of deployment):
- **Bedrock Titan Embeddings**: ~$0.0001 per 1K tokens
- **Bedrock Claude v2**: ~$0.002 per 1K tokens
- **Lambda**: $0.20 per 1M requests + compute time
- **S3**: $0.023 per GB/month
- **DynamoDB**: On-demand pricing ~$1.25 per million write requests
- **API Gateway**: $1.00 per million requests

**Typical query cost**: $0.002 - $0.005 per request

---

## Next Steps

1. ✓ Deploy infrastructure: `./deploy.sh`
2. Test basic functionality
3. Implement multi-tenant isolation (see TODO.md)
4. Add evaluation metrics
5. Implement guardrails and security controls

See [TODO.md](TODO.md) for complete roadmap.
