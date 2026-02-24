#!/bin/bash
# Setup script for pushing to GitHub with secrets protection

set -e  # Exit on error

echo "🚀 RAG GenAI - GitHub Repository Setup"
echo "========================================"
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📦 Initializing git repository..."
    git init
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already initialized"
fi

# Set default branch to main
echo ""
echo "🌿 Setting default branch to main..."
git branch -M main
echo "✅ Default branch set to main"

# Remove any nested .git directories that might interfere
echo ""
echo "🧹 Cleaning up nested git repositories..."
find . -path "./.git" -prune -o -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
echo "✅ Cleanup complete"

# Add remote
echo ""
echo "🔗 Adding remote repository..."
git remote remove origin 2>/dev/null || true  # Remove if exists
git remote add origin git@github.com:kcarterlabs/gen-ai-rag.git
echo "✅ Remote 'origin' added"

# Stage all files
echo ""
echo "📝 Staging files..."
git add -A
echo "✅ Files staged"

# Show status
echo ""
echo "📊 Git Status:"
git status --short

# Create initial commit
echo ""
echo "💾 Creating initial commit..."
git commit -m "Initial commit: RAG GenAI serverless system

Features:
- Multi-tenant RAG with AWS Bedrock
- 7 Terraform modules (storage, database, lambda, api_gateway, iam, policies, alarms)
- 12 CloudWatch alarms with SNS notifications
- Security scanning with Gitleaks
- GitHub Actions for Terraform deployment
- Comprehensive guardrails and cost tracking
" || echo "⚠️  No changes to commit or already committed"

# Set main branch
echo ""
echo "🌿 Setting main branch..."
git branch -M main

echo ""
echo "✅ Repository setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  IMPORTANT: Set up AWS OIDC Authentication FIRST!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔐 Recommended: Use OIDC (no long-lived credentials)"
echo ""
echo "Option 1 - Automated (Terraform):"
echo "  cd infra/oidc-setup"
echo "  terraform init"
echo "  terraform apply"
echo "  # Copy the role ARN from output"
echo ""
echo "Option 2 - Manual (AWS Console):"
echo "  See AWS_OIDC_SETUP.md for step-by-step instructions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After OIDC setup, add GitHub repository secrets:"
echo "  https://github.com/kcarterlabs/gen-ai-rag/settings/secrets/actions"
echo ""
echo "Required secrets:"
echo "   ┌─────────────────────────┬────────────────────────────────────┐"
echo "   │ Secret Name             │ Purpose                            │"
echo "   ├─────────────────────────┼────────────────────────────────────┤"
echo "   │ AWS_ROLE_ARN            │ OIDC role for Terraform            │"
echo "   │ ALARM_EMAIL             │ CloudWatch alarm notifications     │"
echo "   │ GITLEAKS_LICENSE        │ Secret scanning (private repo)     │"
echo "   └─────────────────────────┴────────────────────────────────────┘"
echo ""
echo "📖 See GITHUB_SECRETS_SETUP.md and AWS_OIDC_SETUP.md for details"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After setting secrets, push to GitHub:"
echo ""
echo "  git push -u origin main"
echo ""
echo "This will trigger:"
echo "  ✓ Security scan (Gitleaks)"
echo "  ✓ Terraform deployment (on main branch)"
echo ""
