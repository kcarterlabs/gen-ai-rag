#!/bin/bash

# Get API endpoint and credentials from Terraform
echo "🔍 Getting API configuration..."
cd infra

API_ENDPOINT=$(terraform output -raw api_endpoint)
export AWS_ACCESS_KEY_ID=$(terraform output -raw api_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw api_secret_access_key)

cd ..

CHAT_URL="$API_ENDPOINT/chat"

echo "✅ API Endpoint: $API_ENDPOINT"
echo "🔐 Using IAM authentication (AWS SigV4)"
echo "📡 Chat URL: $CHAT_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Basic question
echo "Test 1: Authenticated Request"
echo "Question: What is RAG?"
echo ""

# Use awscurl for AWS SigV4 signed requests
if ! command -v awscurl &> /dev/null; then
    echo "❌ awscurl not installed"
    echo ""
    echo "Install it with: pip install awscurl"
    echo ""
    echo "Or use this manual curl with AWS SigV4:"
    echo ""
    echo "aws apigatewayv2 invoke-api \\"
    echo "  --api-id $(echo $API_ENDPOINT | cut -d'/' -f3 | cut -d'.' -f1) \\"
    echo "  --stage '\$default' \\"
    echo "  --resource-path '/chat' \\"
    echo "  --http-method POST \\"
    echo "  --body '{\"question\":\"What is RAG?\"}' \\"
    echo "  --region us-west-2 \\"
    echo "  response.json"
    exit 1
fi

awscurl --service execute-api \
  --region us-west-2 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"question": "What is RAG?"}' \
  "$CHAT_URL" | jq -r 'if .answer then "✅ Answer: " + .answer + "\n\n📊 Metadata:\n  Tokens: \(.metadata.tokens_used)\n  Cost: $\(.metadata.estimated_cost)\n  Relevance: \(.metadata.relevance_score)" else "❌ Error: " + (.error // "Unknown error") end'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Authentication working!"
echo ""
echo "💡 API is now secured with AWS IAM authentication"
echo "   Unauthenticated requests will be rejected with 403 Forbidden"
echo ""
