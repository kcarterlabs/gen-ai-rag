#!/bin/bash
# Deployment script for RAG GenAI infrastructure

set -e

echo "======================================"
echo "RAG GenAI - Deployment Script"
echo "======================================"

# Change to script directory
cd "$(dirname "$0")"

# Step 1: Package Lambda functions
echo ""
echo "Step 1: Packaging Lambda functions..."
echo "--------------------------------------"

# Create temporary build directory
mkdir -p build
cd build

# Copy Python files
cp ../*.py .

# Install dependencies compatible with Lambda runtime (Amazon Linux 2)
if [ -s ../requirements.txt ]; then
    echo "Installing dependencies for Lambda runtime (Amazon Linux 2)..."
    pip install -r ../requirements.txt -t . \
        --platform manylinux2014_x86_64 \
        --only-binary=:all: \
        --python-version 3.11 \
        --implementation cp
else
    echo "No dependencies to install (requirements.txt is empty)"
fi

# Create deployment package
echo "Creating lambda.zip..."
zip -r ../infra/lambda.zip . -x "*.pyc" -x "__pycache__/*"

# Cleanup
cd ..
rm -rf build

echo "✓ Lambda package created: infra/lambda.zip"

# Step 2: Deploy with Terraform
echo ""
echo "Step 2: Deploying infrastructure with Terraform..."
echo "---------------------------------------------------"

cd infra

# Initialize Terraform (if not already done)
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Plan deployment
echo ""
echo "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this deployment? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "Applying deployment..."
    terraform apply tfplan
    rm tfplan
    
    echo ""
    echo "======================================"
    echo "✓ Deployment Complete!"
    echo "======================================"
    echo ""
    echo "Important outputs:"
    terraform output
    
    echo ""
    echo "Next steps:"
    echo "  1. Test the chat endpoint:"
    echo "     curl -X POST \$(terraform output -raw chat_url) \\"
    echo "       -H 'Content-Type: application/json' \\"
    echo "       -d '{\"question\": \"What is machine learning?\"}'"
    echo ""
    echo "  2. Upload a document to trigger ingestion:"
    echo "     aws s3 cp test.txt s3://\$(terraform output -raw vector_bucket_name)/uploads/test.txt"
else
    echo "Deployment cancelled."
    rm tfplan
fi
