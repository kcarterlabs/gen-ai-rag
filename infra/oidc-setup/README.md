# OIDC Setup via Terraform

This directory contains Terraform configuration to automatically create the OIDC provider and IAM role for GitHub Actions.

## When to Use This

- **Automated setup**: Prefer this over manual AWS Console steps
- **Reproducible**: Can recreate in any AWS account
- **Version controlled**: Infrastructure as code

## Prerequisites

- AWS CLI configured with admin credentials
- Terraform >= 1.5.0

## Usage

### 1. Initialize Terraform

```bash
cd infra/oidc-setup
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

This will create:
- OIDC Identity Provider: `token.actions.githubusercontent.com`
- IAM Role: `GitHubActionsRAGTerraformRole`
- IAM Policy: `GitHubActionsRAGTerraformPolicy`

### 3. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Optional**: Set trust policy mode (default is `main-only` for security):

```bash
# Most secure: Only main branch (no AWS warning)
terraform apply -var="trust_policy_mode=main-only"

# Flexible: All branches and PRs (AWS will show warning)
terraform apply -var="trust_policy_mode=all-branches"

# Balanced: Specific branches + PRs (no AWS warning)
terraform apply -var="trust_policy_mode=specific-branches" \
  -var='allowed_branches=["main","develop"]'
```

**Security Recommendation**: Use `main-only` for production, `specific-branches` for development.

### 4. Copy the Role ARN

After apply completes, you'll see:

```
Outputs:

github_actions_role_arn = "arn:aws:iam::123456789012:role/GitHubActionsRAGTerraformRole"
```

### 5. Add to GitHub Secrets

Go to: https://github.com/kcarterlabs/gen-ai-rag/settings/secrets/actions

Add secret:
- **Name**: `AWS_ROLE_ARN`
- **Value**: The ARN from step 4

### 6. Remove Old Secrets

Delete these secrets (no longer needed with OIDC):
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 7. Test

```bash
cd ../..  # Back to repo root
git commit --allow-empty -m "test: verify OIDC authentication"
git push origin main
```

Check GitHub Actions to verify the workflow runs successfully with OIDC.

## Customization

Edit variables in `main.tf` or pass via command line:

```bash
# Change repository
terraform apply \
  -var="github_org=myorg" \
  -var="github_repo=myrepo"

# Change trust policy mode
terraform apply \
  -var="trust_policy_mode=main-only"

# Allow specific branches
terraform apply \
  -var="trust_policy_mode=specific-branches" \
  -var='allowed_branches=["main","staging","develop"]'
```

### Trust Policy Modes

| Mode               | Security | AWS Warning | PRs Can Plan? | Description |
|--------------------|----------|-------------|---------------|-------------|
| `main-only`        | ✅ High  | ❌ No       | ❌ No         | Only main branch can assume role |
| `specific-branches`| ✅ Good  | ❌ No       | ✅ Yes        | Specific branches + PRs explicitly listed |
| `all-branches`     | ⚠️ Lower | ⚠️ Yes      | ✅ Yes        | Any branch/PR can assume role (uses wildcard) |

**Recommendation**: 
- Production: `main-only`
- Development: `specific-branches`
- Avoid `all-branches` unless you understand the security implications

## Cleanup

To remove the OIDC setup:

```bash
terraform destroy
```

**Warning**: This will break GitHub Actions deployments until you recreate the setup.

## Outputs

- `oidc_provider_arn` - ARN of the OIDC provider (or more specific based on trust_policy_mode)
- Session duration is 1 hour
- Uses least-privilege IAM policy for Terraform operations
- CloudTrail will log all role assumptions
- **Trust policy mode**:
  - `main-only`: Most secure, eliminates AWS wildcard warning
  - `specific-branches`: Balanced security with explicit branch list
  - `all-branches`: Most flexible but triggers AWS security warning

**To avoid AWS wildcard warning**: Use `main-only` or `specific-branches` mode.

## Security Notes

- Role is restricted to your specific repository: `repo:kcarterlabs/gen-ai-rag:*`
- Session duration is 1 hour
- Uses least-privilege IAM policy for Terraform operations
- CloudTrail will log all role assumptions

## Alternative: Manual Setup

If you prefer manual AWS Console steps, see [AWS_OIDC_SETUP.md](../../AWS_OIDC_SETUP.md).
