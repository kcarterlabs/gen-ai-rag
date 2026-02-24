#!/bin/bash
set -e

echo "🔄 Importing existing AWS resources into Terraform state..."
echo "This will add resources that were created in previous runs to the state file."
echo ""

cd infra

# Set alarm email from environment or prompt
if [ -z "$TF_VAR_alarm_email" ]; then
    echo "⚠️  TF_VAR_alarm_email not set"
    echo "Please run: export TF_VAR_alarm_email=your-email@example.com"
    exit 1
fi

echo "📦 Initializing Terraform..."
terraform init

echo ""
echo "🔍 Importing existing resources..."

# Import S3 bucket
echo "  → S3 bucket: rag-genai-vectors"
terraform import module.storage.aws_s3_bucket.bucket rag-genai-vectors || echo "    Already imported or doesn't exist"

# Import DynamoDB table
echo "  → DynamoDB table: rag-genai-costs"
terraform import module.database.aws_dynamodb_table.table rag-genai-costs || echo "    Already imported or doesn't exist"

# Import IAM role
echo "  → IAM role: rag-genai-lambda-role"
terraform import module.iam.aws_iam_role.lambda_role rag-genai-lambda-role || echo "    Already imported or doesn't exist"

# Import IAM policies
echo "  → IAM policy: rag-genai-bedrock-invoke"
POLICY_ARN=$(aws iam list-policies --scope Local --query 'Policies[?PolicyName==`rag-genai-bedrock-invoke`].Arn' --output text)
if [ -n "$POLICY_ARN" ]; then
    terraform import module.policies.aws_iam_policy.bedrock_invoke "$POLICY_ARN" || echo "    Already imported"
else
    echo "    Policy not found, skipping"
fi

echo "  → IAM policy: rag-genai-s3-vector-access"
POLICY_ARN=$(aws iam list-policies --scope Local --query 'Policies[?PolicyName==`rag-genai-s3-vector-access`].Arn' --output text)
if [ -n "$POLICY_ARN" ]; then
    terraform import module.policies.aws_iam_policy.s3_vector_access "$POLICY_ARN" || echo "    Already imported"
else
    echo "    Policy not found, skipping"
fi

echo "  → IAM policy: rag-genai-dynamodb-cost-access"
POLICY_ARN=$(aws iam list-policies --scope Local --query 'Policies[?PolicyName==`rag-genai-dynamodb-cost-access`].Arn' --output text)
if [ -n "$POLICY_ARN" ]; then
    terraform import module.policies.aws_iam_policy.dynamodb_cost_access "$POLICY_ARN" || echo "    Already imported"
else
    echo "    Policy not found, skipping"
fi

# Import CloudWatch log group
echo "  → CloudWatch log group: /aws/apigateway/rag-genai"
terraform import module.api_gateway.aws_cloudwatch_log_group.api_gateway /aws/apigateway/rag-genai || echo "    Already imported or doesn't exist"

# Import Lambda functions
echo "  → Lambda function: rag-genai-chat"
terraform import module.lambda.aws_lambda_function.chat rag-genai-chat || echo "    Already imported or doesn't exist"

echo "  → Lambda function: rag-genai-ingest"
terraform import module.lambda.aws_lambda_function.ingest rag-genai-ingest || echo "    Already imported or doesn't exist"

# Import API Gateway integrations
echo "  → API Gateway chat integration"
API_ID=$(aws apigatewayv2 get-apis --query 'Items[?Name==`rag-genai-api`].ApiId' --output text 2>/dev/null)
if [ -n "$API_ID" ]; then
    INTEGRATION_ID=$(aws apigatewayv2 get-integrations --api-id "$API_ID" --query 'Items[?contains(IntegrationUri, `rag-genai-chat`)].IntegrationId' --output text 2>/dev/null)
    if [ -n "$INTEGRATION_ID" ]; then
        terraform import module.api_gateway.aws_apigatewayv2_integration.chat "$API_ID/$INTEGRATION_ID" || echo "    Already imported"
    fi
    
    ROUTE_ID=$(aws apigatewayv2 get-routes --api-id "$API_ID" --query 'Items[?RouteKey==`POST /chat`].RouteId' --output text 2>/dev/null)
    if [ -n "$ROUTE_ID" ]; then
        echo "  → API Gateway chat route"
        terraform import module.api_gateway.aws_apigatewayv2_route.chat "$API_ID/$ROUTE_ID" || echo "    Already imported"
    fi
fi

echo ""
echo "✅ Import complete!"
echo ""
echo "Now running terraform plan to verify..."
terraform plan

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Resources imported successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Review the plan output above"
echo "2. Commit the state changes: git add . && git commit -m 'chore: import existing resources'"
echo "3. Push to trigger GitHub Actions again"
echo ""
