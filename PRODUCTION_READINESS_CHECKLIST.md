# PRODUCTION_READINESS_CHECKLIST.md

Use this before deploying to real users.

---

## 1. Retrieval Quality

[ ] Precision@k measured
[ ] Recall@k measured
[ ] Empty retrieval rate < 5%
[ ] Chunk size tested for optimal recall

---

## 2. Cost Control

[ ] Token budget enforced
[ ] top_k dynamically adjustable
[ ] Embedding deduplication implemented
[ ] Monthly cost alarm configured
[ ] Per-tenant cost tracking enabled

---

## 3. Security

[ ] Least-privilege IAM roles
[ ] S3 bucket private
[ ] Encryption at rest enabled
[ ] TLS enforced
[ ] Tenant isolation verified
[ ] Prompt injection mitigation added

---

## 4. Observability

[ ] CloudWatch logs enabled
[ ] LLM latency tracked
[ ] Embedding latency tracked
[ ] Error rate tracked
[ ] Empty retrieval metric tracked

---

## 5. Performance

[ ] Average response time < 3 seconds
[ ] Cold start impact measured
[ ] Memory usage optimized
[ ] Streaming enabled (optional)

---

## 6. Reliability

[ ] Timeout handling implemented
[ ] Retry logic for Bedrock calls
[ ] Graceful fallback on retrieval failure
[ ] Dead-letter queue for failed ingestion

---

## 7. Compliance & Governance

[ ] Data retention policy defined
[ ] PII handling defined
[ ] Logging retention defined
[ ] Audit trail available

---

## 8. Scalability

[ ] Tested with large documents
[ ] Tested with high query volume
[ ] DynamoDB capacity mode validated
[ ] S3 prefix design avoids hot partitions

---

## 9. Exam Readiness

You can confidently explain:

[ ] RAG architecture
[ ] Cost drivers in GenAI
[ ] Guardrails and safety controls
[ ] Multi-tenant isolation
[ ] Observability strategy
[ ] Trade-offs between vector stores
[ ] Latency vs accuracy trade-offs

If all boxes are checked, you are production-ready AND exam-ready.
