# GitHub Secrets Setup Guide

This project uses GitHub Secrets to protect sensitive information like email addresses and AWS credentials.

## Authentication Methods

### ✅ Recommended: OIDC Authentication
Use OpenID Connect for secure, keyless authentication between GitHub Actions and AWS.

**Benefits**:
- No long-lived credentials
- Automatic credential rotation
- Better security and audit trail

📖 **See [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md) for complete OIDC setup guide**

### Alternative: Access Keys (Legacy)
Use IAM user access keys (not recommended for production).

---

## Required Secrets (OIDC Method)

Set these secrets in your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**

### 1. AWS_ROLE_ARN ⭐ (OIDC)
**Purpose**: IAM Role ARN for GitHub Actions to assume via OIDC  
**Example**: `arn:aws:iam::123456789012:role/GitHubActionsRAGTerraformRole`

**How to get this**:
- Follow [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md) to create the OIDC provider and role
- Or use automated setup: `cd infra/oidc-setup && terraform apply`

### 2. ALARM_EMAIL
**Purpose**: Email address for CloudWatch alarm notifications  
**Example**: `your.email@example.com`

```bash
# This replaces the hardcoded email in config.yaml
# Terraform will use this via TF_VAR_alarm_email environment variable
```

### 3. GITLEAKS_LICENSE (Optional)
**Purpose**: Gitleaks license key for secret scanning  
**Note**: Free for public repositories, license needed for private repos

---

## Required Secrets (Access Keys Method - Legacy)

**⚠️ Not recommended**: Use OIDC instead for better security

If you must use access keys:

### 1. ALARM_EMAIL
Same as above

### 2. AWS_ACCESS_KEY_ID
**Purpose**: AWS IAM access key for Terraform deployment  
**Security**: Use an IA (Optional)
**Purpose**: Gitleaks license key for secret scanning  
**Note**: Free for public repositories, license needed for private repos

**To use access keys**: You must modify `.github/workflows/terraform-deploy.yml` to use access keys instead of OIDC.

---

## Quick Setup (OIDC - Recommended)te, delete)
- DynamoDB (create, update, delete)
- API Gateway (create, update, delete)
- IAM (create roles, policies)
- CloudWatch (create alarms, log groups)
- SNS (create topics, subscriptions)

### 3. AWS_SECRET_ACCESS_KEY
**Purpose**: AWS IAM secret access key  
**Security**: Never commit this to the repository

### 4. GITLEAKS_LICENSE
**Purpose**: Gitleaks license key for secret scanning  
**Note**: Free for public repositories, license needed for private repos

## Setting Secrets

### Via GitHub UI

1. Go to repository **Settings**
2. Click **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter secret name and value
5. Click **Add secret**

### Verify Secrets Are Set
OIDC method - you should see:
# - AWS_ROLE_ARN
# - ALARM_EMAIL
# - GITLEAKS_LICENSE (if using private repo)

# Access keys method - you should see:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - ALARM_EMAILs and variables → Actions
# You should see:
# - ALARM_EMAIL
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - GITLEAKS_LICENSE (if using private repo)
```

## Local Development

For local Terraform runs, set the alarm email as an environment variable:

```bash
# Option 1: Inline with terraform command
export TF_VAR_alarm_email="your.email@example.com"
terraform plan
terraform apply

# Option 2: Create terraform.tfvars (DO NOT commit this file)
echo 'alarm_email = "your.email@example.com"' > infra/terraform.tfvars
cd infra
terraform plan
terraform apply
```

**Important**: `terraform.tfvars` is in `.gitignore` to prevent accidental commits.

## GitHub Actions Workflows

### Security Scan (security-scan.yml)
**Triggers**: Push, PR, Weekly schedule  
**SeWS_ROLE_ARN` - OIDC role for AWS authentication (recommended)
  OR
- `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` - Access keys (legacy)
- `ALARM_EMAIL` - CloudWatch notifications

**Purpose**: Scans codebase for accidentally committed secrets

### Terraform Deploy (terraform-deploy.yml)
**Triggers**: Push to main, PR, Manual  
**Secrets Used**:
- `ALARM_EMAIL` - CloudWatch notifications
- `AWS_ACCESS_KEY_ID` - AWS authentication
- `AWS_SECRET_ACCESS_KEY` - AWS authentication
**Use OIDC authentication instead of access keys**
- Use repository secrets for all sensitive data
- Rotate AWS credentials regularly (if using access keys)
- Use IAM roles with minimal permissions
- Enable MFA on AWS account
- Review GitHub Actions logs (secrets are masked)
- Use environment protection rules for production

### ❌ DON'T
- Commit secrets to git (even in private repos)
- Share secrets via email or chat
- Use admin/root AWS credentials
- Store secrets in config files
- Push terraform.tfvars to git
- Use long-lived access keys when OIDC is available
### ❌ DON'T
- Commit secrets to git (even in private repos)
- Share secrets via email or chat
- Use admin/root AWS credentials
- Store secrets in config files
- Push terraform.tfvars to git
### OIDC Method

1. **Check secrets are configured**:
   ```bash
   # In GitHub UI: Settings → Secrets → Actions
   # Should see: AWS_ROLE_ARN, ALARM_EMAIL
   ```

2. **Verify OIDC provider in AWS**:
   ```bash
   aws iam list-open-id-connect-providers
   # Should see: token.actions.githubusercontent.com
   ```
4. **Test Terraform workflow** (on main branch):
   ```bash
   # Make a change to infra/
   git add infra/config.yaml
   git commit -m "test: trigger terraform workflow"
   git push origin main
   # Check Actions tab - "Terraform Deploy" should run
   # Look for "Assuming role with OIDC" in logs
   ```

### Access Keys Method
OIDC Issues

### "Error: Not authorized to perform sts:AssumeRoleWithWebIdentity"
**Problem**: Trust policy doesn't match GitHub repository or OIDC provider not found  
**Solution**: 
1. Verify OIDC provider exists in AWS IAM
2. Check trust policy includes: `repo:kcarterlabs/gen-ai-rag:*`
3. Ensure `AWS_ROLE_ARN` secret is set correctly

### "No OpenID Connect provider found"
**Problem**: OIDC provider not created in AWS  
**Solution**: Run `cd infra/oidc-setup && terraform apply` or follow [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md)

### Access Key Issues

### 
Follow steps 1, 2, and 3 from OIDC method above.heck Actions tab - "Security Scan" should pass
   ```

3. **Test Terraform workflow** (on main branch):
   ```bash
   # Make a change to infra/
   AWS OIDC Setup Guide](AWS_OIDC_SETUP.md) - Complete OIDC configuration
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [git add infra/config.yaml
   git commit -m "test: trigger terraform workflow"
   git push origin main
   # Check Actions tab - "Terraform Deploy" should run
   ```

## Troubleshooting

### "Error: No value for required variable"
**Problem**: `alarm_email` variable not set  
**Solution**: Ensure `ALARM_EMAIL` secret is configured in GitHub

### "Error: Invalid AWS credentials"
**Problem**: AWS secrets not set or incorrect  
**Solution**: 
1. Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set
2. Test credentials locally: `aws sts get-caller-identity`
3. Check IAM user has required permissions

### "Gitleaks scan failed"
**Problem**: Potential secret detected  
**Solution**: 
1. Review the scan output in Actions logs
2. If false positive, update `.gitleaks.toml` allowlist
3. If real secret, rotate it immediately and use GitHub Secrets instead

## Additional Resources

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Gitleaks Configuration](https://github.com/gitleaks/gitleaks#configuration)
