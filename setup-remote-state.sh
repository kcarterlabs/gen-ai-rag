#!/bin/bash
# Setup Terraform Remote State Backend

set -e

echo "🔧 Setting up Terraform Remote State"
echo "====================================="
echo ""

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $ACCOUNT_ID"
echo ""

# Check if already exists
STATE_BUCKET="rag-genai-terraform-state-$ACCOUNT_ID"
if aws s3 ls "s3://$STATE_BUCKET" 2>/dev/null; then
    echo "✅ State bucket already exists: $STATE_BUCKET"
    echo ""
    echo "Skipping backend setup..."
else
    echo "📦 Creating remote state infrastructure..."
    cd infra/backend-setup
    
    terraform init
    terraform apply -var="account_id=$ACCOUNT_ID" -auto-approve
    
    cd ../..
    echo ""
    echo "✅ Remote state infrastructure created!"
fi

echo ""
echo "🔄 Initializing main infrastructure with remote backend..."
cd infra

# Check if .terraform exists
if [ -d ".terraform" ]; then
    echo "⚠️  Existing Terraform state found"
    echo ""
    read -p "Do you want to migrate existing state to S3? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform init -migrate-state -force-copy
    else
        echo "Skipping state migration"
        terraform init -reconfigure
    fi
else
    terraform init
fi

cd ..

echo ""
echo "✅ Remote State Setup Complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "State Configuration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Bucket:        $STATE_BUCKET"
echo "Lock Table:    rag-genai-terraform-locks"
echo "Region:        us-west-2"
echo "Encryption:    AES256"
echo "Versioning:    Enabled"
echo ""
echo "Cost: ~$0.05/month"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Verify state is in S3:"
echo "   aws s3 ls s3://$STATE_BUCKET/"
echo ""
echo "2. Commit backend configuration:"
echo "   git add infra/main.tf infra/backend-setup/"
echo "   git commit -m 'feat: add Terraform remote state backend'"
echo "   git push"
echo ""
echo "3. GitHub Actions will now use remote state automatically!"
echo ""
