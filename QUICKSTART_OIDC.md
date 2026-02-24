# Quick Start: OIDC Setup for GitHub Actions

This is the fastest way to set up secure AWS authentication for GitHub Actions.

## Why OIDC?

✅ No long-lived AWS credentials  
✅ Automatic credential rotation  
✅ Better security and audit trail  
✅ Recommended by AWS and GitHub  

## Quick Setup (5 minutes)

### Option 1: Automated Setup (Recommended)

```bash
# 1. Navigate to OIDC setup directory
cd infra/oidc-setup

# 2. Initialize Terraform
terraform init

# 3. Create OIDC provider and IAM role
# Most secure: Only main branch (no AWS warning)
terraform apply -var="trust_policy_mode=main-only"
# Type 'yes' when prompted

# Alternative: Allow PRs + specific branches (no AWS warning)
# terraform apply -var="trust_policy_mode=specific-branches"

# Alternative: Allow all branches (AWS will show warning)
# terraform apply -var="trust_policy_mode=all-branches"

# 4. Copy the role ARN from output (looks like):
# arn:aws:iam::123456789012:role/GitHubActionsRAGTerraformRole
```

**Trust Policy Options**:
- **`main-only`** (default) - Most secure, only main branch ✅ No AWS warning
- **`specific-branches`** - Balanced, specific branches + PRs ✅ No AWS warning  
- **`all-branches`** - Flexible, all branches/PRs ⚠️ AWS shows wildcard warning

See [infra/oidc-setup/README.md](infra/oidc-setup/README.md) for details.

### Option 2: AWS Console (Manual)

Follow [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md) for step-by-step console instructions.

## Configure GitHub Secrets

1. Go to: https://github.com/kcarterlabs/gen-ai-rag/settings/secrets/actions

2. Click **New repository secret**

3. Add these secrets:

   | Secret Name    | Value                                                      |
   |----------------|-------------------------------------------------------------|
   | `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsRAGTerraformRole` |
   | `ALARM_EMAIL`  | `kenneth.carter@kcarterlabs.tech`                          |

4. **Optional** (for private repos):
   - `GITLEAKS_LICENSE` - Your Gitleaks license key

## Test the Setup

```bash
# Push to trigger GitHub Actions
git commit --allow-empty -m "test: verify OIDC authentication"
git push origin main

# Check GitHub Actions:
# https://github.com/kcarterlabs/gen-ai-rag/actions
# Look for "✅ Assuming role with OIDC" in the workflow logs
```

## What Got Created?

In AWS:
- **OIDC Provider**: `token.actions.githubusercontent.com`
- **IAM Role**: `GitHubActionsRAGTerraformRole` (scoped to your repo)
- **IAM Policy**: `GitHubActionsRAGTerraformPolicy` (Terraform permissions)

In GitHub:
- Workflow already configured to use OIDC (see `.github/workflows/terraform-deploy.yml`)

## Verify in AWS CloudTrail

1. Go to CloudTrail console
2. Filter events by username: `GitHubActionsRAGTerraformRole`
3. You should see `AssumeRoleWithWebIdentity` events when workflows run

## Troubleshooting

### "Error: Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Fix**: Check the trust policy includes your repo:
```bash
aws iam get-role --role-name GitHubActionsRAGTerraformRole --query 'Role.AssumeRolePolicyDocument'
# Should see: "repo:kcarterlabs/gen-ai-rag:*"
```

### "No OpenID Connect provider found"

**Fix**: OIDC provider wasn't created. Run:
```bash
cd infra/oidc-setup
terraform apply
```

### Workflow fails with "Access Denied"

**Fix**: Role needs more permissions. Update the policy in `infra/oidc-setup/main.tf` and run `terraform apply`.

## Next Steps

✅ OIDC is set up and working!

Now you can:
- Deploy infrastructure: Push to `main` branch triggers automatic deployment
- Run locally: `export TF_VAR_alarm_email="your@email.com" && terraform apply`
- See [README.md](README.md) for full deployment guide

## Security Notes

🔒 **Role is restricted to**:
- Your specific repository: `kcarterlabs/gen-ai-rag`
- Specific AWS account: Your account ID
- Session duration: 1 hour max

🔒 **No secrets stored**:
- GitHub never stores AWS credentials
- Temporary tokens generated per workflow run
- Tokens expire automatically

## Full Documentation

- [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md) - Complete manual setup guide
- [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) - All secret configuration
- [infra/oidc-setup/README.md](infra/oidc-setup/README.md) - Terraform automation details
