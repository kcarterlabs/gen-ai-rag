# Terraform Remote State Setup

This directory contains Terraform configuration to set up remote state storage in S3 with DynamoDB locking.

## Why Remote State?

**Problem**: Terraform state file (`terraform.tfstate`) doesn't persist between GitHub Actions runs, causing "resource already exists" errors.

**Solution**: Store state in S3 so all runs (local and GitHub Actions) share the same state.

## What Gets Created

1. **S3 Bucket**: Stores `terraform.tfstate` with versioning and encryption
2. **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## Setup (One-Time)

### 1. Run Backend Setup

```bash
cd infra/backend-setup

# Initialize
terraform init

# Create state infrastructure
terraform apply -var="account_id=856817629634"
```

### 2. Note the Outputs

After `apply` completes, you'll see:
```
state_bucket_name = "rag-genai-terraform-state-856817629634"
lock_table_name   = "rag-genai-terraform-locks"
backend_configuration = "..."
```

### 3. Update Main Infrastructure

Copy the backend configuration and add it to `infra/main.tf`:

```hcl
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
```

### 4. Migrate Existing State (if any)

```bash
cd ../  # Back to infra/
terraform init -migrate-state
```

Type `yes` when prompted to copy state to S3.

### 5. Verify

```bash
# Check state is in S3
aws s3 ls s3://rag-genai-terraform-state-856817629634/

# Should see: terraform.tfstate
```

### 6. Commit Changes

```bash
cd ..  # Back to repo root
git add infra/main.tf infra/backend-setup/
git commit -m "feat: add Terraform remote state backend"
git push
```

## GitHub Actions Integration

Once remote state is configured, GitHub Actions automatically uses it. No workflow changes needed!

The OIDC role already has S3 and DynamoDB permissions for state management.

## Cost

**~$0.05/month**:
- S3 storage: $0.023 per GB (state files are tiny)
- DynamoDB: $0.00 (on-demand, minimal requests)
- S3 requests: Negligible

## Troubleshooting

### "Error acquiring state lock"

**Cause**: Previous run crashed without releasing lock  
**Fix**: 
```bash
# Get lock ID from error message
terraform force-unlock <LOCK_ID>
```

### "Backend initialization required"

**Cause**: Backend configured but not initialized  
**Fix**:
```bash
cd infra
terraform init -migrate-state
```

### "Access Denied" in GitHub Actions

**Cause**: OIDC role needs S3/DynamoDB permissions  
**Fix**: Policy should include:
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:ListBucket",
    "dynamodb:PutItem",
    "dynamodb:GetItem",
    "dynamodb:DeleteItem"
  ],
  "Resource": [
    "arn:aws:s3:::rag-genai-terraform-state-*/*",
    "arn:aws:s3:::rag-genai-terraform-state-*",
    "arn:aws:dynamodb:*:*:table/rag-genai-terraform-locks"
  ]
}
```

## Cleanup (Danger Zone)

**⚠️ Warning**: This deletes your state history!

```bash
# Only do this if you want to start completely fresh
cd infra/backend-setup

# Disable lifecycle protection first
terraform apply -var="account_id=856817629634" \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_dynamodb_table.terraform_locks

# Then destroy
terraform destroy -var="account_id=856817629634"
```

## Best Practices

✅ **DO**:
- Keep backend setup in version control
- Enable versioning on state bucket
- Use DynamoDB for locking
- Encrypt state at rest
- Block public access to state bucket

❌ **DON'T**:
- Manually edit state files
- Disable state locking
- Share state bucket across unrelated projects
- Store secrets in state (use external secret management)

## Alternative: Terraform Cloud

Instead of S3 backend, you can use Terraform Cloud (free tier):
- No infrastructure to manage
- Better collaboration features
- Built-in state versioning and locking

See: https://app.terraform.io/
