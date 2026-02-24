#!/bin/bash

echo "🔑 Setting up API credentials for authenticated requests"
echo ""
echo "Step 1: Make sure your AWS credentials are fresh"
echo "----------------------------------------"
echo "Run: aws sso login (or aws configure)"
echo ""
read -p "Press Enter once you've refreshed your AWS credentials..."
echo ""

echo "Step 2: Getting API credentials from Terraform..."
echo "----------------------------------------"
cd infra

API_ACCESS_KEY=$(terraform output -raw api_access_key_id 2>/dev/null)
API_SECRET_KEY=$(terraform output -raw api_secret_access_key 2>/dev/null)

if [ -z "$API_ACCESS_KEY" ] || [ -z "$API_SECRET_KEY" ]; then
    echo "❌ Failed to get credentials from Terraform"
    echo ""
    echo "Make sure:"
    echo "  1. Your AWS credentials are valid (run: aws sts get-caller-identity)"
    echo "  2. Terraform deployment completed successfully"
    echo "  3. The api_access module was deployed"
    exit 1
fi

cd ..

echo "✅ Got credentials!"
echo ""
echo "Step 3: Set these environment variables:"
echo "----------------------------------------"
echo ""
echo "export AWS_ACCESS_KEY_ID='$API_ACCESS_KEY'"
echo "export AWS_SECRET_ACCESS_KEY='$API_SECRET_KEY'"
echo "export AWS_DEFAULT_REGION='us-west-2'"
echo ""
echo "Or run: source <(./get-api-credentials.sh export)"
echo ""
echo "Step 4: Test the API:"
echo "----------------------------------------"
echo "./test-chat-authenticated.sh"
echo ""

if [ "$1" = "export" ]; then
    export AWS_ACCESS_KEY_ID="$API_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$API_SECRET_KEY"  
    export AWS_DEFAULT_REGION="us-west-2"
    echo "✅ Environment variables exported in this shell"
fi
