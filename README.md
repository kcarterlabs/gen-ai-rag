# RAG GenAI - Serverless Document Q&A System

[![Security Scan](https://github.com/kcarterlabs/gen-ai-rag/actions/workflows/security-scan.yml/badge.svg)](https://github.com/kcarterlabs/gen-ai-rag/actions/workflows/security-scan.yml)

Production-ready serverless RAG (Retrieval-Augmented Generation) system built on AWS with comprehensive monitoring, security, and cost tracking.

## 🏗️ Architecture

Multi-tenant serverless RAG system with:
- **AWS Lambda** - Serverless compute for chat and document ingestion
- **Amazon Bedrock** - Claude v2 for generation, Titan for embeddings
- **S3** - Vector storage with server-side encryption
- **DynamoDB** - Cost tracking per tenant
- **API Gateway** - HTTP API with CORS support
- **CloudWatch** - 12 production alarms with SNS notifications

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture and data flow diagrams.

## ✨ Features

- **Multi-tenant isolation** - Tenant-specific S3 prefixes and DynamoDB partitions
- **Comprehensive guardrails** - Content filtering, PII detection, prompt injection protection
- **Cost tracking** - Per-tenant Bedrock usage logged to DynamoDB with custom CloudWatch metrics
- **Production monitoring** - 12 CloudWatch alarms covering Lambda, API Gateway, DynamoDB
- **Secure by default** - IAM least privilege, S3 encryption, audit logging
- **Evaluation framework** - Answer relevance, groundedness, faithfulness metrics

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.5.0
- Python 3.11+
- Git

### Setup AWS OIDC Authentication (Recommended)

For secure, keyless GitHub Actions deployment:

```bash
# Automated setup
cd infra/oidc-setup
terraform init
terraform apply
# Copy the role ARN and add as AWS_ROLE_ARN GitHub secret
```

Or follow [QUICKSTART_OIDC.md](QUICKSTART_OIDC.md) for step-by-step instructions.

### Deploy Infrastructure

```bash
# Clone the repository
git clone git@github.com:kcarterlabs/gen-ai-rag.git
cd gen-ai-rag

# Set your alarm email (for local development)
export TF_VAR_alarm_email="your.email@example.com"
# OR copy and edit terraform.tfvars
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit infra/terraform.tfvars with your email

# Initialize and deploy
cd infra
terraform init
terraform plan
terraform apply

# Package and deploy Lambda code
cd ..
./deploy.sh
```

**For GitHub Actions deployment**: See [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) for configuring repository secrets.

### Configure Alarms

After deployment, confirm your SNS subscription:
1. Check your email for SNS subscription confirmation
2. Click the confirmation link
3. Alarms will now send notifications

### Upload Documents

```bash
# Upload a document to trigger ingestion
aws s3 cp document.pdf s3://rag-genai-vectors/uploads/tenant-123/document.pdf
```

### Query via API

```bash
# Get API endpoint
terraform output api_endpoint

# Send chat request
curl -X POST https://your-api.execute-api.us-west-2.amazonaws.com/chat \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "tenant-123",
    "question": "What does the document say about...?",
    "doc_id": "document"
  }'
```

## 📊 Cost Estimation

### POC / Development (50 queries/month)
- **Total: ~$0.45/month**
- Lambda: $0.00 (within free tier)
- S3: $0.03
- DynamoDB: $0.00 (within free tier)
- Bedrock: $0.40
- CloudWatch: $1.80
- API Gateway: $0.00

### Moderate Usage (10k queries/month)
- **Total: ~$47/month**
- See [COST_ESTIMATION](COST_ESTIMATION) for detailed breakdown

Run cost simulator:
```bash
python cost_simulator.py
python poc_cost_comparison.py
```

## 🔐 Security

- **IAM Least Privilege** - Scoped policies for Bedrock, S3, DynamoDB
- **Encryption** - S3 (AES256), DynamoDB (AWS managed)
- **Input Validation** - Guardrails for content, PII, prompt injection
- **Audit Logging** - Structured logs with security context
- **Secret Scanning** - Automated Gitleaks scan on every commit

See [PRODUCTION_READINESS_CHECKLIST.md](PRODUCTION_READINESS_CHECKLIST.md) for security details.

## 📈 Monitoring

12 CloudWatch alarms:
- Lambda errors, duration, throttles, concurrent executions
- API Gateway 4xx/5xx errors, latency
- DynamoDB throttles
- High token usage (cost spike protection)
- Composite system health

See [CLOUDWATCH_ALARMS.md](CLOUDWATCH_ALARMS.md) for alarm details.

## 🧪 Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
python test_infrastructure.py  # Validates Terraform modules
python simple_test.py          # Tests chunking without AWS
python test_local.py           # Tests with mocked AWS
```

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for comprehensive testing strategies.

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and data flows
- [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment guide
- [CLOUDWATCH_ALARMS.md](CLOUDWATCH_ALARMS.md) - Monitoring and alerting
- [PRODUCTION_READINESS_CHECKLIST.md](PRODUCTION_READINESS_CHECKLIST.md) - Production checklist
- [TODO.md](TODO.md) - Roadmap and planned features
- [ROADMAP.md](ROADMAP.md) - Long-term vision

## 📁 Project Structure

```
.
├── bedrock_client.py          # Bedrock API wrapper with cost tracking
├── chat_handler.py            # Lambda handler for chat queries
├── ingest_handler.py          # Lambda handler for document ingestion
├── chunking.py                # Document chunking logic
├── vector_store.py            # S3-based vector storage
├── guardrails.py              # Content filtering and validation
├── security.py                # Security utilities and logging
├── evaluation.py              # RAG evaluation metrics
├── prompt_templates.py        # Prompt engineering templates
├── infra/                     # Terraform infrastructure
│   ├── main.tf
│   ├── config.yaml            # Centralized configuration
│   └── modules/               # Terraform modules
│       ├── alarms/            # CloudWatch alarms
│       ├── api_gateway/       # HTTP API
│       ├── database/          # DynamoDB
│       ├── iam/               # IAM roles
│       ├── lambda/            # Lambda functions
│       ├── policies/          # IAM policies
│       └── storage/           # S3 buckets
├── deploy.sh                  # Lambda deployment script
└── requirements.txt           # Python dependencies
```

## 🛣️ Roadmap

High-priority items:
- [ ] API Gateway throttling controls
- [ ] Budget alarms (AWS Budgets)
- [ ] Dead Letter Queue (DLQ) for failed messages
- [ ] Multi-environment support (dev/staging/prod)
- [ ] API key authentication
- [ ] Query result caching

See [TODO.md](TODO.md) for complete roadmap.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

All commits are automatically scanned for secrets using Gitleaks.

## 📝 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Kenneth Carter**  
KCarter Labs  
kenneth.carter@kcarterlabs.tech

## 🙏 Acknowledgments

- Amazon Bedrock for LLM infrastructure
- Terraform AWS modules community
- CloudWatch alarms best practices from AWS

---

**Status**: Production-ready POC with comprehensive monitoring and security controls
