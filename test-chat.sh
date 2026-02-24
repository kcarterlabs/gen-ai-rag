#!/bin/bash

echo "🔍 Getting API endpoint from Terraform..."
API_ENDPOINT=$(cd infra && terraform output -raw api_endpoint 2>/dev/null)

if [ -z "$API_ENDPOINT" ]; then
    echo "❌ Could not get API endpoint from Terraform"
    echo ""
    echo "Make sure infrastructure is deployed:"
    echo "  cd infra && terraform output api_endpoint"
    exit 1
fi

CHAT_URL="$API_ENDPOINT/chat"

echo "✅ API Endpoint: $API_ENDPOINT"
echo "📡 Chat URL: $CHAT_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Basic question
echo "Test 1: Basic Question"
echo "Question: What is RAG?"
echo ""
curl -s -X POST "$CHAT_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is RAG?"
  }' | jq -r 'if .answer then "✅ Answer: " + .answer + "\n\n📊 Metadata:\n  Tokens: \(.metadata.tokens_used)\n  Cost: $\(.metadata.estimated_cost)\n  Relevance: \(.metadata.relevance_score)" else "❌ Error: " + (.error // "Unknown error") + (if .reason then "\n   Reason: " + .reason else "" end) end'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 2: Question with context
echo "Test 2: Question with Tenant/User Context"
echo "Question: How does retrieval-augmented generation work?"
echo "Tenant: acme-corp"
echo "User: test-user@example.com"
echo ""
curl -s -X POST "$CHAT_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How does retrieval-augmented generation work?",
    "tenant_id": "acme-corp",
    "user_id": "test-user@example.com"
  }' | jq -r 'if .answer then "✅ Answer: " + .answer + "\n\n📊 Metadata:\n  Tokens: \(.metadata.tokens_used)\n  Cost: $\(.metadata.estimated_cost)\n  Relevance: \(.metadata.relevance_score)\n\n📚 Sources: \(.sources | length) chunks retrieved" else "❌ Error: " + (.error // "Unknown error") + (if .reason then "\n   Reason: " + .reason else "" end) end'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 3: Empty question (should fail)
echo "Test 3: Empty Question (Should Fail with 400)"
echo ""
curl -s -X POST "$CHAT_URL" \
  -H "Content-Type: application/json" \
  -d '{}' | jq -r 'if .error then "❌ Expected Error: " + .error else "⚠️  Unexpected success" end'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Testing complete!"
echo ""
echo "💡 Tips:"
echo "  • Full API docs: See TEST_API.md"
echo "  • Monitor logs: aws logs tail /aws/lambda/rag-genai-chat --follow --region us-west-2"
echo "  • Add documents: Use POST /ingest endpoint (see INGEST.md)"
echo ""
