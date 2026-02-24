---

# 🏗 Infrastructure & Terraform Expansion

## IAM Hardening

### [✓] Add Bedrock Invoke Permissions
- ✓ Allow:
  - bedrock:InvokeModel
  - bedrock:InvokeModelWithResponseStream
- ✓ Restrict to specific model ARNs (Titan, Claude)
- ✓ Avoid wildcard permissions
- **Implemented in:** `infra/modules/policies/main.tf`

### [✓] Add Least-Privilege S3 Policy
- ✓ Allow:
  - GetObject
  - PutObject
  - DeleteObject
- ✓ Restrict to vector bucket ARN
- ✓ ListBucket with bucket-level scope
- **Implemented in:** `infra/modules/policies/main.tf`

### [✓] Add DynamoDB Scoped Access
- ✓ Allow:
  - PutItem
  - Query
  - GetItem
- ✓ Restrict to cost table ARN
- **Implemented in:** `infra/modules/policies/main.tf`

---

## API Gateway

### [✓] Add HTTP API (API Gateway v2)
- ✓ Create POST /chat endpoint
- ✓ Integrate with Lambda (AWS_PROXY)
- ✓ Enable CORS
- ✓ CloudWatch access logging
- **Implemented in:** `infra/modules/api_gateway/`
- **Note:** POST /ingest not needed (uses S3 event trigger instead)

### [ ] Add Throttling Controls
- Rate limiting
- Burst limits
- Protect against cost spikes
- **Priority:** HIGH - Prevents cost overruns

---

## Terraform Improvements

### [✓] Split into Modules
- ✓ modules/lambda
- ✓ modules/storage (S3)
- ✓ modules/database (DynamoDB)
- ✓ modules/api_gateway
- ✓ modules/policies (IAM)
- **Implemented in:** `infra/modules/`

### [ ] Add Multi-Environment Support (3+ Environments)
- **Environment structure**: dev / staging / prod / qa / demo
- Environment-specific config files (config.dev.yaml, config.prod.yaml)
- Environment prefix in all resource names (e.g., rag-genai-dev-chat)
- Separate cost modeling per environment
- **Scaling considerations:**
  - Terraform workspaces OR separate state files per environment
  - Environment-specific Bedrock model configurations (smaller models for dev)
  - Different Lambda memory/timeout per environment (512MB dev, 1024MB prod)
  - Environment-specific throttling limits (lower for dev)
  - Separate S3 buckets per environment (avoid cross-environment data leakage)
  - Environment-specific DynamoDB capacity (on-demand dev, provisioned prod)
  - Conditional resource creation (e.g., WAF only in prod)
- **Implementation approach:**
  ```
  infra/
    ├── environments/
    │   ├── dev/
    │   │   ├── terraform.tfvars
    │   │   └── backend.tf
    │   ├── staging/
    │   ├── prod/
    │   └── qa/
    └── modules/ (shared)
  ```
- **Priority:** HIGH - Required for proper dev/test/prod separation

### [✓] Add Lambda Deployment Automation
- ✓ Auto-zip source files (deploy.sh)
- ✓ Use source_code_hash
- ✓ Prevent unnecessary redeployments
- **Implemented in:** `deploy.sh`

### [✓] Add Outputs
- ✓ API endpoint URL
- ✓ S3 bucket name
- ✓ DynamoDB table name
- ✓ Lambda ARNs
- **Implemented in:** `infra/ouputs.tf`

---✓] Enable S3 Encryption (SSE-S3 or SSE-KMS)
- ✓ AES256 encryption enabled
- **Implemented in:** `infra/modules/storage/main.tf`

### [✓] Enable DynamoDB Encryption (default)
- ✓ Encryption at rest enabled by default

### [ ] Enable Lambda environment variable encryption
- **Priority:** MEDIUM - Encrypt sensitive env vars with KMS

### [✓] Add CloudWatch log retention policy
- ✓ 7-day retention for Lambda logs
- ✓ 7-day retention for API Gateway logs
- **Implemented in:** Lambda and API Gateway modules

### [ ] Add IAM Access Analyzer validation
- **Priority:** LOW - Validates least-privilege policiesE-KMS)
### [ ] Enable DynamoDB Encryption (default)
- **Priority:** HIGH - Critical for production monitoring

### [✓] Add Structured Logging (JSON)
- ✓ Include:
  - tenant_id
  - request_id
  - tokens_used
  - cost_estimate
- ✓ Audit logging with SecurityContext
- **Implemented in:** `chat_handler.py`, `ingest_handler.py`, `security.py`

### [ ] Add X-Ray Tracing
- Trace:
  - Retrieval latency
  - Bedrock latency
  - Total request duration
- **Priority:** MEDIUM - Useful for performance optimiz
### [ ] Add Structured Logging (JSON)
- Include:
  - tenant_id
  - request_id
  - tokens_used
  - cost_estimate

### [ ] Add X-Ray Tracing
- Trace:
  - Retrieval latency
  - Bedrock latency
  - Total request duration

---

## Scalability & Performance

### [ ] Add Reserved Concurrency Limits
- Prevent runaway cost
- Environment-specific limits (10 for dev, 100 for prod)
- **Priority:** MEDIUM

### [ ] Add S3 Prefix Sharding Strategy
- Avoid hot partitions at scale
- Example:
  s3://bucket/{tenant_id}/{hash_prefix}/{doc_id}.json
- Use first 2 chars of doc_id hash as shard key
- **Priority:** LOW - Only needed at high scale (>10k docs/tenant)

### [ ] Evaluate Migration to OpenSearch
- Trigger threshold:
  - >100k documents
  - >1M vectors
- Compare retrieval latency vs cost
- Consider OpenSearch Serverless for auto-scaling
- **Priority:** LOW - Only needed at enterprise scale

---

## Multi-Environment Scaling Infrastructure

### [ ] Add Environment-Aware Deployment Pipeline
- Automated deployment workflow (GitHub Actions / CodePipeline)
- Environment promotion: dev → staging → prod
- Automated testing in staging before prod deployment
- Blue/green deployment strategy for zero downtime
- **Priority:** HIGH - Essential for managing 3+ environments

### [ ] Add Environment-Specific Resource Tagging
- Consistent tagging strategy across all environments
- Tags: Environment, CostCenter, Owner, Project, ManagedBy
- Enable cost allocation by environment
- AWS Cost Explorer filtering by environment tag
- **Priority:** HIGH - Critical for cost tracking across environments

### [ ] Add Cross-Environment Monitoring Dashboard
- Unified CloudWatch dashboard showing all environments
- Comparison metrics: dev vs staging vs prod
- Environment health status at a glance
- Cost comparison across environments
- **Priority:** MEDIUM

### [ ] Add Environment Isolation & Network Segmentation
- Separate VPCs per environment (if moving beyond serverless)
- VPC endpoints for privatelink to Bedrock/S3 (enhanced security)
- Security group rules preventing cross-environment access
- Separate KMS keys per environment
- **Priority:** MEDIUM - Enterprise security requirement

### [ ] Add Configuration Management at Scale
- Centralized parameter store (SSM Parameter Store / Secrets Manager)
- Environment-specific secrets (API keys, DB credentials)
- Automatic secret rotation per environment
- Configuration validation before deployment
- **Priority:** HIGH - Prevents configuration drift

### [ ] Add Infrastructure State Management
- Remote state backend per environment (S3 + DynamoDB locking)
- State file isolation (prevent dev changes affecting prod)
- State backup and versioning strategy
- Terraform state encryption
- Example structure:
  ```
  s3://terraform-state-bucket/
    ├── dev/terraform.tfstate
    ├── staging/terraform.tfstate
    └── prod/terraform.tfstate
  ```
- **Priority:** HIGH - Prevents state corruption across environments

### [ ] Add Auto-Scaling Policies per Environment
- Lambda concurrency auto-scaling based on load
- DynamoDB auto-scaling (if switching from on-demand)
- API Gateway usage plans per environment
- Environment-specific scaling thresholds
- **Priority:** MEDIUM - Optimizes cost vs performance

### [ ] Add Disaster Recovery Strategy
- Cross-region replication for prod environment
- Backup strategy per environment (frequent for prod, minimal for dev)
- Point-in-time recovery testing
- RTO/RPO targets per environment (stricter for prod)
- **Priority:** MEDIUM - Production resilience

---

## Cost Protection
- **Priority:** HIGH - Prevents unexpected bills

### [✓] Add Token Budget Enforcement in Lambda
- ✓ Hard max per request (4000 tokens)
- ✓ Reject overly large prompts
- ✓ Input length validation (10000 chars)
- **Implemented in:** `guardrails.py`

### [ ] Add Tier-Based Limits
- Free tier
- Pro tier
- Enterprise tier
- **Priority:** LOW - Business logic feature
### [ ] Add Tier-Based Limits
- Free tier
- Pro tier
- Enterprise tier

---

## Production Readiness Level 2

### [ ] Add WAF in Front of API Gateway
### [ ] Add Authentication (Cognito or JWT)
### [ ] Add Request Validation Schema
### [ ] Add Dead Letter Queue (SQS) for ingestion failures

---

# 🎯 Stretch: Enterprise Architecture

### [ ] Replace S3 Vector Store with Managed Vector DB
- Evaluate:
  - OpenSearch Serverless
  - Aurora PostgreSQL + pgvector

### [ ] Add Re-Ranking Model
### [ ] Add Caching Layer (Redis / ElastiCache)
- Cache frequent query embeddings
- Cache top_k retrieval results

---

If you complete everything in this TODO:

You will have:
✔ Production-grade serverless RAG  
✔ Cost-governed architecture  
✔ Multi-tenant isolation  
✔ Observability + guardrails  
✔ Infrastructure-as-Code maturity  

At that point, you're not just exam-ready — you're architect-level.
