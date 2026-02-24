#!/bin/bash

echo "🔍 RAG GenAI Deployment Diagnostics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Lambda functions
echo "1️⃣  Checking Lambda Functions..."
echo ""
LAMBDAS=$(aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `rag-genai`)].FunctionName' --region us-west-2 --output text)

if [ -z "$LAMBDAS" ]; then
    echo "❌ No Lambda functions found starting with 'rag-genai'"
    echo "   Deployment may not have completed successfully"
else
    echo "✅ Found Lambda functions:"
    for lambda in $LAMBDAS; do
        echo "   - $lambda"
        STATE=$(aws lambda get-function --function-name "$lambda" --region us-west-2 --query 'Configuration.State' --output text 2>/dev/null)
        echo "     State: $STATE"
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check API Gateway
echo "2️⃣  Checking API Gateway..."
echo ""
API_ID="as8jlggb9g"
API_EXISTS=$(aws apigatewayv2 get-api --api-id "$API_ID" --region us-west-2 2>&1)

if echo "$API_EXISTS" | grep -q "NotFoundException"; then
    echo "❌ API Gateway not found: $API_ID"
else
    echo "✅ API Gateway exists: $API_ID"
    
    # Check routes
    echo ""
    echo "   Routes configured:"
    aws apigatewayv2 get-routes --api-id "$API_ID" --region us-west-2 --query 'Items[].{Route:RouteKey,Target:Target}' --output table 2>&1 | head -20
    
    # Check integrations
    echo ""
    echo "   Integrations:"
    aws apigatewayv2 get-integrations --api-id "$API_ID" --region us-west-2 --query 'Items[].{Type:IntegrationType,URI:IntegrationUri}' --output table 2>&1 | head -20
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check recent Lambda logs
echo "3️⃣  Checking Recent Lambda Logs (last 5 minutes)..."
echo ""

if [ -n "$LAMBDAS" ]; then
    for lambda in $LAMBDAS; do
        echo "   Logs for $lambda:"
        aws logs tail "/aws/lambda/$lambda" --since 5m --region us-west-2 --format short 2>&1 | head -10 || echo "     No recent logs or log group doesn't exist"
        echo ""
    done
else
    echo "   ⚠️  No Lambda functions to check logs for"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test API endpoint
echo "4️⃣  Testing API Endpoint..."
echo ""
API_ENDPOINT="https://as8jlggb9g.execute-api.us-west-2.amazonaws.com/chat"
echo "   Endpoint: $API_ENDPOINT"
echo ""

RESPONSE=$(curl -s -w "\n\nHTTP_CODE:%{http_code}" -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{"question": "test"}' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "   Response Code: $HTTP_CODE"
echo "   Response Body:"
echo "$BODY" | jq -r '.' 2>/dev/null || echo "$BODY"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Terraform state
echo "5️⃣  Checking Terraform State..."
echo ""
if [ -f "infra/.terraform/terraform.tfstate" ] || [ -f "infra/terraform.tfstate" ]; then
    cd infra
    LAMBDA_COUNT=$(terraform state list 2>/dev/null | grep -c "aws_lambda_function" || echo "0")
    echo "   Lambda functions in state: $LAMBDA_COUNT"
    
    # Check if specific resources exist
    terraform state show module.lambda.aws_lambda_function.chat >/dev/null 2>&1 && echo "   ✅ Chat Lambda in state" || echo "   ❌ Chat Lambda NOT in state"
    terraform state show module.lambda.aws_lambda_function.ingest >/dev/null 2>&1 && echo "   ✅ Ingest Lambda in state" || echo "   ❌ Ingest Lambda NOT in state"
    cd ..
else
    echo "   ⚠️  No local Terraform state found (using remote state)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary
echo "📋 Summary & Next Steps:"
echo ""

if [ -z "$LAMBDAS" ]; then
    echo "❌ LAMBDAS NOT DEPLOYED"
    echo ""
    echo "Possible causes:"
    echo "  1. GitHub Actions deployment hasn't completed successfully"
    echo "  2. Resources were imported but Lambda functions weren't created"
    echo "  3. Deployment failed and you need to run: ./import-existing-resources.sh"
    echo ""
    echo "Check GitHub Actions:"
    echo "  https://github.com/kcarterlabs/gen-ai-rag/actions"
    echo ""
    echo "Or deploy manually:"
    echo "  cd infra"
    echo "  export TF_VAR_alarm_email=kenneth.carter@kcarterlabs.tech"
    echo "  terraform plan"
    echo "  terraform apply"
else
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ DEPLOYMENT SUCCESSFUL - API is working!"
    elif [ -n "$HTTP_CODE" ]; then
        echo "⚠️  DEPLOYMENT INCOMPLETE - API returns HTTP $HTTP_CODE"
        echo ""
        echo "Check Lambda logs above for errors"
        echo "You may need to:"
        echo "  1. Complete resource import: ./import-existing-resources.sh"
        echo "  2. Update Lambda code"
        echo "  3. Check IAM permissions (Bedrock, S3, DynamoDB access)"
    else
        echo "❌ API UNREACHABLE"
        echo ""
        echo "API Gateway exists but not responding"
        echo "Check integrations above - Lambda may not be connected"
    fi
fi

echo ""
