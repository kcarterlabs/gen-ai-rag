#!/bin/bash

echo "🔑 Setting up AWS profile for API credentials"
echo ""

# First, make sure main AWS credentials are valid
echo "Step 1: Checking your main AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ Your main AWS credentials are not valid"
    echo "Run: aws sso login"
    exit 1
fi
echo "✅ Main credentials valid"
echo ""

# Get API credentials from Terraform
echo "Step 2: Getting API credentials from Terraform..."
cd infra

API_ACCESS_KEY=$(terraform output -raw api_access_key_id 2>/dev/null)
API_SECRET_KEY=$(terraform output -raw api_secret_access_key 2>/dev/null)

if [ -z "$API_ACCESS_KEY" ] || [ -z "$API_SECRET_KEY" ]; then
    echo "❌ Failed to get credentials from Terraform"
    echo ""
    echo "Error: Cannot access Terraform state"
    echo "Make sure you've run 'aws sso login' first"
    exit 1
fi

cd ..

echo "✅ Got credentials!"
echo ""

# Add profile to ~/.aws/credentials
echo "Step 3: Adding 'rag-genai-api' profile to ~/.aws/credentials..."

PROFILE_NAME="rag-genai-api"
CREDENTIALS_FILE="$HOME/.aws/credentials"

# Create ~/.aws directory if it doesn't exist
mkdir -p ~/.aws

# Check if profile already exists
if grep -q "\[$PROFILE_NAME\]" "$CREDENTIALS_FILE" 2>/dev/null; then
    echo "⚠️  Profile '$PROFILE_NAME' already exists. Updating..."
    # Remove existing profile
    sed -i "/\[$PROFILE_NAME\]/,/^$/d" "$CREDENTIALS_FILE"
fi

# Add new profile
cat >> "$CREDENTIALS_FILE" << EOF

[$PROFILE_NAME]
aws_access_key_id = $API_ACCESS_KEY
aws_secret_access_key = $API_SECRET_KEY
region = us-west-2
EOF

echo "✅ Profile added to ~/.aws/credentials"
echo ""
echo "Step 4: Test the profile:"
echo "----------------------------------------"
echo "aws sts get-caller-identity --profile $PROFILE_NAME"
echo ""
echo "Step 5: Use it with your test script:"
echo "----------------------------------------"
echo "AWS_PROFILE=$PROFILE_NAME ./test-chat-authenticated.sh"
echo ""
echo "Or export it for the session:"
echo "export AWS_PROFILE=$PROFILE_NAME"
echo "./test-chat-authenticated.sh"
echo ""
