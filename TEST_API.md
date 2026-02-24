# Testing the Chat Lambda API

## Get Your API Endpoint

Once the infrastructure is deployed, get the API endpoint URL:

```bash
cd infra
terraform output api_endpoint
```

The endpoint will be in format: `https://{api-id}.execute-api.us-west-2.amazonaws.com`

## Chat Endpoint

**Endpoint:** `POST /chat`

**Full URL:** `{api_endpoint}/chat`

## Request Format

### Basic Request

```bash
curl -X POST https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/chat \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is RAG?"
  }'
```

### Request with Tenant & User ID

```bash
curl -X POST https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/chat \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How do embeddings work?",
    "tenant_id": "company-123",
    "user_id": "user-456"
  }'
```

## Request Body Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question` | string | **Yes** | The user's question |
| `tenant_id` | string | No | Tenant identifier for multi-tenancy (default: "default") |
| `user_id` | string | No | User identifier for auditing (default: "anonymous") |

## Response Format

### Success Response (200)

```json
{
  "answer": "RAG stands for Retrieval-Augmented Generation...",
  "sources": [
    {
      "text": "Retrieved context chunk 1...",
      "similarity": 0.92
    },
    {
      "text": "Retrieved context chunk 2...",
      "similarity": 0.87
    }
  ],
  "metadata": {
    "model": "anthropic.claude-v2",
    "tokens_used": 450,
    "estimated_cost": 0.00135,
    "response_time_ms": 1250,
    "relevance_score": 0.85
  }
}
```

### Error Responses

**400 Bad Request** - Missing question or guardrail violation:
```json
{
  "error": "No question provided"
}
```

```json
{
  "error": "Request blocked by security guardrails",
  "reason": "Potential prompt injection detected"
}
```

**500 Internal Server Error** - Processing error:
```json
{
  "error": "Failed to process request",
  "message": "Error details..."
}
```

## Security Features

The chat endpoint includes:

✅ **Input validation** - Max length 5000 characters  
✅ **PII detection** - Automatically masks sensitive data  
✅ **Prompt injection detection** - Blocks malicious inputs  
✅ **Tenant isolation** - Data is scoped by tenant_id  
✅ **Audit logging** - All requests logged with user context  
✅ **Rate limiting** - Via CloudWatch alarms  

## Example Test Script

Save as `test-chat.sh`:

```bash
#!/bin/bash

# Get API endpoint from Terraform
API_ENDPOINT=$(cd infra && terraform output -raw api_endpoint)

echo "Testing Chat API: $API_ENDPOINT/chat"
echo ""

# Test 1: Basic question
echo "Test 1: Basic question"
curl -X POST "$API_ENDPOINT/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is machine learning?"
  }' | jq .

echo ""
echo "─────────────────────────────────────"
echo ""

# Test 2: Question with context
echo "Test 2: Question with tenant/user context"
curl -X POST "$API_ENDPOINT/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Explain neural networks",
    "tenant_id": "acme-corp",
    "user_id": "john.doe@acme.com"
  }' | jq .

echo ""
echo "─────────────────────────────────────"
echo ""

# Test 3: Empty question (should fail)
echo "Test 3: Empty question (should return 400)"
curl -X POST "$API_ENDPOINT/chat" \
  -H "Content-Type: application/json" \
  -d '{}' | jq .
```

Make it executable:
```bash
chmod +x test-chat.sh
./test-chat.sh
```

## Python Example

```python
import requests
import json

# Get your API endpoint from: cd infra && terraform output api_endpoint
API_ENDPOINT = "https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com"

def ask_question(question, tenant_id="default", user_id="test-user"):
    """Ask a question to the RAG system"""
    
    url = f"{API_ENDPOINT}/chat"
    
    payload = {
        "question": question,
        "tenant_id": tenant_id,
        "user_id": user_id
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    response = requests.post(url, json=payload, headers=headers)
    
    if response.status_code == 200:
        result = response.json()
        print(f"Answer: {result['answer']}\n")
        print(f"Sources: {len(result.get('sources', []))} chunks retrieved")
        print(f"Cost: ${result['metadata']['estimated_cost']:.6f}")
        print(f"Relevance: {result['metadata']['relevance_score']:.2f}")
    else:
        print(f"Error {response.status_code}: {response.text}")
    
    return response.json()

# Example usage
if __name__ == "__main__":
    # Test basic question
    ask_question("What is retrieval-augmented generation?")
    
    # Test with context
    ask_question(
        "How does RAG improve LLM responses?",
        tenant_id="mycompany",
        user_id="user123"
    )
```

## JavaScript/Node.js Example

```javascript
const API_ENDPOINT = "https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com";

async function askQuestion(question, tenantId = "default", userId = "test-user") {
  const response = await fetch(`${API_ENDPOINT}/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      question,
      tenant_id: tenantId,
      user_id: userId,
    }),
  });

  const data = await response.json();
  
  if (response.ok) {
    console.log(`Answer: ${data.answer}\n`);
    console.log(`Sources: ${data.sources?.length || 0} chunks`);
    console.log(`Cost: $${data.metadata.estimated_cost.toFixed(6)}`);
    console.log(`Relevance: ${data.metadata.relevance_score.toFixed(2)}`);
  } else {
    console.error(`Error ${response.status}:`, data);
  }
  
  return data;
}

// Example usage
askQuestion("What is RAG?");
```

## Verify Deployment

Check if the Lambda and API are deployed:

```bash
# Check Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `rag-genai`)].FunctionName' --region us-west-2

# Check API Gateway
aws apigatewayv2 get-apis --query 'Items[?Name==`rag-genai-api`]' --region us-west-2

# Get API endpoint
cd infra && terraform output api_endpoint
```

## Monitoring

Check CloudWatch Logs:

```bash
# Chat Lambda logs
aws logs tail /aws/lambda/rag-genai-chat --follow --region us-west-2

# API Gateway logs
aws logs tail /aws/apigateway/rag-genai --follow --region us-west-2
```

## Cost Tracking

Each response includes estimated cost:

```json
{
  "metadata": {
    "tokens_used": 450,
    "estimated_cost": 0.00135
  }
}
```

Costs are also logged to the `rag-genai-costs` DynamoDB table for tracking.

## Next Steps

1. **Add documents** - Use the ingest endpoint to add content (see INGEST.md)
2. **Monitor usage** - Check CloudWatch alarms and DynamoDB cost table
3. **Test guardrails** - Try malicious inputs to verify security
4. **Review logs** - Check audit logs in CloudWatch

## Troubleshooting

**"Internal Server Error"**
- Check Lambda logs: `aws logs tail /aws/lambda/rag-genai-chat --follow --region us-west-2`
- Verify Bedrock model access in IAM role
- Check vector store has documents

**"No similar documents found"**
- You need to ingest documents first
- Use the POST /ingest endpoint to add content

**"Guardrail violation"**
- Input contains potential security issues
- Check error message for specific reason
- Remove PII or injection patterns from question
