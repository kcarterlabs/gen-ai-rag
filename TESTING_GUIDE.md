# Testing Guide

## Prerequisites

1. **AWS CLI configured** with credentials
2. **Python 3.11** installed
3. **Terraform** installed (for deployment)

---

## Option 1: Local Testing (No AWS Required)

Test individual components locally:

```bash
python test_local.py
```

**Note:** This will fail when calling actual AWS services (Bedrock, S3, DynamoDB) but helps validate code structure.

---

## Option 2: Deploy to AWS and Test

### Step 1: Install Dependencies

```bash
pip install boto3
```

### Step 2: Package Lambda Functions

```bash
# Create deployment package
zip -r lambda.zip *.py
```

### Step 3: Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### Step 4: Get API Endpoint

```bash
# After deployment, get the API Gateway URL from outputs
terraform output api_endpoint
```

### Step 5: Test Chat Endpoint

```bash
# Replace <API_ENDPOINT> with your actual endpoint
curl -X POST <API_ENDPOINT>/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "What is machine learning?"}'
```

### Step 6: Test Ingest by Uploading Document

```bash
# Upload a test document to S3
echo "Machine learning is awesome" > test.txt
aws s3 cp test.txt s3://<VECTOR_BUCKET>/test-tenant/test.txt
```

---

## Option 3: Unit Testing with Mocks

Create proper unit tests using `moto` (AWS mocking library):

```bash
pip install moto pytest
pytest tests/
```

---

## Current Limitations

⚠️ **Before you can test:**

1. **API Gateway not configured** - Need to add to Terraform
2. **Lambda deployment incomplete** - Need to create lambda.zip with dependencies
3. **Bedrock permissions missing** - Need to add IAM policies
4. **Dependencies not specified** - requirements.txt is empty

See [TODO.md](TODO.md) for complete list of tasks.

---

## Quick Start (Manual Testing)

If you just want to test the **Python logic** without AWS:

```python
from chunking import chunk_text
from prompt_templates import build_prompt

# Test chunking
text = "Your document here..."
chunks = chunk_text(text)
print(f"Created {len(chunks)} chunks")

# Test prompt building
prompt = build_prompt(chunks, "What is this about?")
print(prompt)
```
