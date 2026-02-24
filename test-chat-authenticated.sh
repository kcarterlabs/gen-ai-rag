#!/bin/bash

# Get API endpoint from Terraform
echo "🔍 Getting API configuration..."
cd infra
API_ENDPOINT=$(terraform output -raw api_endpoint)
cd ..

CHAT_URL="$API_ENDPOINT/chat"

echo "✅ API Endpoint: $API_ENDPOINT"
echo "🔐 Using IAM authentication (AWS SigV4)"
echo "📡 Chat URL: $CHAT_URL"

# Check authentication method
if [ -n "$AWS_PROFILE" ]; then
    echo "👤 Using AWS profile: $AWS_PROFILE"
elif [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "🔑 Using credentials from environment variables"
else
    echo ""
    echo "❌ No AWS credentials found!"
    echo ""
    echo "Option 1 (Recommended): Use AWS profile"
    echo "  ./setup-api-profile.sh"
    echo "  AWS_PROFILE=rag-genai-api ./test-chat-authenticated.sh"
    echo ""
    echo "Option 2: Use environment variables"
    echo "  export AWS_ACCESS_KEY_ID='...'"
    echo "  export AWS_SECRET_ACCESS_KEY='...'"
    echo "  ./test-chat-authenticated.sh"
    exit 1
fi
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
    exit 1
fi

# Make the authenticated request
if [ -n "$AWS_PROFILE" ]; then
    # Use AWS profile (awscurl will pick it up from the profile)
    awscurl --service execute-api \
      --region us-west-2 \
      --profile "$AWS_PROFILE" \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"question": "What is RAG?", "tenant_id": "test-tenant"}' \
      "$CHAT_URL" | jq -r 'if .answer then "✅ Answer: " + .answer + "\n\n📊 Metadata:\n  Tokens: \(.metadata.tokens_used)\n  Cost: $\(.metadata.estimated_cost)\n  Relevance: \(.metadata.relevance_score)" else "❌ Error: " + (.error // "Unknown error") end'
else
    # Use environment variables (awscurl picks up AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
    awscurl --service execute-api \
      --region us-west-2 \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"question": "What is RAG?", "tenant_id": "test-tenant"}' \
      "$CHAT_URL" | jq -r 'if .answer then "✅ Answer: " + .answer + "\n\n📊 Metadata:\n  Tokens: \(.metadata.tokens_used)\n  Cost: $\(.metadata.estimated_cost)\n  Relevance: \(.metadata.relevance_score)" else "❌ Error: " + (.error // "Unknown error") end'
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Authentication working!"
echo ""
echo "💡 API is now secured with AWS IAM authentication"
echo "   Unauthenticated requests will be rejected with 403 Forbidden"
echo ""
