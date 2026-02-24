# AWS OIDC Setup for GitHub Actions

This guide shows how to set up secure OIDC (OpenID Connect) authentication between GitHub Actions and AWS, eliminating the need for long-lived AWS access keys.

## Benefits of OIDC vs Access Keys

✅ **No long-lived credentials** - Tokens expire automatically  
✅ **No secret rotation** - AWS generates temporary credentials  
✅ **Better security** - Role-based access with specific repo restrictions  
✅ **Audit trail** - CloudTrail shows which GitHub workflow assumed the role  

## AWS Console Setup

### Step 1: Create OIDC Identity Provider

1. **Open IAM Console**: https://console.aws.amazon.com/iam/
2. Click **Identity providers** → **Add provider**
3. Configure provider:
   - **Provider type**: `OpenID Connect`
   - **Provider URL**: `https://token.actions.githubusercontent.com`
   - **Audience**: `sts.amazonaws.com`
4. Click **Get thumbprint** (auto-populates)
5. Click **Add provider**

✅ **Result**: You should see `token.actions.githubusercontent.com` in your identity providers list

---

### Step 2: Create IAM Role for GitHub Actions

1. **In IAM Console**, click **Roles** → **Create role**

2. **Select trusted entity**:
   - **Trusted entity type**: `Web identity`
   - **Identity provider**: Select `token.actions.githubusercontent.com` (the one you just created)
   - **Audience**: Select `sts.amazonaws.com`

3. **Add GitHub repository restriction** (CRITICAL for security):
   - Click **JSON** tab
   - Replace the trust policy with this:

   **Option A: Main Branch Only (Most Secure)** ✅ Recommended
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
             "token.actions.githubusercontent.com:sub": "repo:kcarterlabs/gen-ai-rag:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```
   ✅ **Most secure**: Only `main` branch can assume role  
   ✅ **No wildcard warning** from AWS  
   ⚠️ **Limitation**: Pull requests cannot run terraform plan  

   **Option B: All Branches and PRs (Flexible)**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:kcarterlabs/gen-ai-rag:*"
           }
         }
       }
     ]
   }
   ```
   ✅ **Flexible**: PRs can run terraform plan for review  
   ✅ **Terraform apply** still protected (only runs on main branch - see workflow)  
   ⚠️ **AWS Warning**: Uses wildcard in sub claim  

   **Option C: Multiple Specific Branches (Balanced)**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "ForAnyValue:StringLike": {
             "token.actions.githubusercontent.com:sub": [
               "repo:kcarterlabs/gen-ai-rag:ref:refs/heads/main",
               "repo:kcarterlabs/gen-ai-rag:ref:refs/heads/develop",
               "repo:kcarterlabs/gen-ai-rag:pull_request"
             ]
           }
         }
       }
     ]
   }
   ```
   ✅ **Balanced**: Specific branches + PRs  
   ✅ **No wildcard**: Explicitly listed sources  
   ✅ **Terraform apply** protected by workflow conditions  

   **Recommendation**: Use **Option A** for production, **Option C** for development environments.

   **Replace `YOUR_ACCOUNT_ID`** with your AWS account ID (find it in top-right of console)

4. Click **Next: Permissions**

5. **Attach permissions policies**:
   
   Click **Create policy** (opens new tab):
   - Click **JSON** tab
   - Paste the policy from Step 3 below
   - Click **Next: Tags** → **Next: Review**
   - **Name**: `GitHubActionsRAGTerraformPolicy`
   - Click **Create policy**
   
   Go back to the role creation tab:
   - Refresh the policy list
   - Search for and select `GitHubActionsRAGTerraformPolicy`

6. Click **Next: Tags** (optional, add tags if desired)

7. Click **Next: Review**
   - **Role name**: `GitHubActionsRAGTerraformRole`
   - **Role description**: `OIDC role for GitHub Actions to deploy RAG infrastructure via Terraform`

8. Click **Create role**

---

### Step 3: Create IAM Policy for Terraform

Use this policy (referenced in Step 2 above):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformLambda",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:ListFunctions",
        "lambda:ListVersionsByFunction",
        "lambda:PublishVersion",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:GetPolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformS3",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketNotification",
        "s3:PutBucketNotification",
        "s3:GetBucketCORS",
        "s3:PutBucketCORS"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformDynamoDB",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable",
        "dynamodb:ListTables",
        "dynamodb:ListTagsOfResource",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:UpdateContinuousBackups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformAPIGateway",
      "Effect": "Allow",
      "Action": [
        "apigateway:GET",
        "apigateway:POST",
        "apigateway:PUT",
        "apigateway:PATCH",
        "apigateway:DELETE",
        "apigateway:UpdateRestApiPolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformIAM",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:UpdateRole",
        "iam:ListRoles",
        "iam:PassRole",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:TagPolicy",
        "iam:UntagPolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformCloudWatch",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:ListTagsLogGroup",
        "logs:TagLogGroup",
        "logs:UntagLogGroup",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListTagsForResource",
        "cloudwatch:TagResource",
        "cloudwatch:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformSNS",
      "Effect": "Allow",
      "Action": [
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:GetTopicAttributes",
        "sns:SetTopicAttributes",
        "sns:Subscribe",
        "sns:Unsubscribe",
        "sns:ListSubscriptionsByTopic",
        "sns:ListTopics",
        "sns:TagResource",
        "sns:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformSTSCallerIdentity",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

**Important Notes**:
- This policy uses `Resource: "*"` for simplicity. For production, scope down to specific resources.
- Consider adding conditions to limit regions: `"Condition": {"StringEquals": {"aws:RequestedRegion": "us-west-2"}}`

---

### Step 4: Copy the Role ARN

1. In **IAM Console** → **Roles**
2. Search for `GitHubActionsRAGTerraformRole`
3. Click on the role
4. **Copy the Role ARN** - looks like:
   ```
   arn:aws:iam::123456789012:role/GitHubActionsRAGTerraformRole
   ```

5. You'll need this for GitHub repository settings

---

## GitHub Repository Setup

### Set the Role ARN as a Secret

1. Go to: https://github.com/kcarterlabs/gen-ai-rag/settings/secrets/actions
2. Click **New repository secret**
3. **Name**: `AWS_ROLE_ARN`
4. **Value**: Paste the role ARN from Step 4 above
5. Click **Add secret**

### Required Secrets Summary

After OIDC setup, you only need these secrets:

| Secret Name      | Purpose                              | Example Value                                           |
|------------------|--------------------------------------|---------------------------------------------------------|
| AWS_ROLE_ARN     | IAM Role for OIDC authentication     | `arn:aws:iam::123456789012:role/GitHubActionsRAGTerraformRole` |
| ALARM_EMAIL      | CloudWatch alarm notifications       | `kenneth.carter@kcarterlabs.tech`                      |
| GITLEAKS_LICENSE | Secret scanning (private repos only) | Your Gitleaks license key                              |

**Note**: You NO LONGER need `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY`!

---

## Verification

### Test the OIDC Setup

1. **Trigger the workflow**:
   ```bash
   git commit --allow-empty -m "test: verify OIDC authentication"
   git push origin main
   ```

2. **Check GitHub Actions**:
   - Go to: https://github.com/kcarterlabs/gen-ai-rag/actions
   - Click on the running workflow
   - Look for "Configure AWS Credentials" step
   - Should see: ✅ "Assuming role with OIDC"

3. **Verify in AWS CloudTrail**:
   - Go to CloudTrail console
   - Filter by username: `GitHubActionsRAGTerraformRole`
   - You should see `AssumeRoleWithWebIdentity` events

### Troubleshooting

#### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause**: Trust policy doesn't match GitHub repository  
**Fix**: Verify the trust policy has correct repo name: `repo:kcarterlabs/gen-ai-rag:*`

#### Error: "No OpenID Connect provider found"

**Cause**: OIDC provider not created  
**Fix**: Complete Step 1 to create the identity provider

#### Error: "Access Denied" during Terraform operations

**Cause**: IAM role missing permissions  
**Fix**: Verify the policy from Step 3 is attached to the role

---

## Alternative: Terraform-Managed OIDC Setup

Instead of manual console setup, you can create a separate Terraform configuration to set up OIDC.

See `infra/oidc-setup/` directory (if you want me to create this).

---

## Security Best Practices

### Understanding the Wildcard Warning

If you use Option B (all branches), AWS shows a warning about the wildcard (`*`). This is a **defense-in-depth** recommendation, not a critical vulnerability.

**Why it's still secure**:
- Your GitHub Actions workflow has conditions that only allow `terraform apply` on main branch
- Terraform plan on PRs is read-only (safe)
- OIDC tokens are short-lived (1 hour)

**To eliminate the warning**: Use Option A (main-only) or Option C (specific branches).

See [OIDC_TRUST_POLICY_GUIDE.md](OIDC_TRUST_POLICY_GUIDE.md) for detailed security analysis.

### ✅ DO
- Restrict OIDC role to specific GitHub repositories
- Use least-privilege IAM policies
- Limit to specific AWS regions in policy conditions
- Enable CloudTrail logging
- Review CloudTrail regularly for unexpected role assumptions
- Use environment protection rules in GitHub

### ❌ DON'T
- Use wildcards in repo restrictions (`repo:*/*:*`)
- Grant AdministratorAccess to the OIDC role
- Allow all principals in trust policy
- Disable CloudTrail
- Reuse the same role across multiple repos

---

## Migration Checklist

- [ ] Create OIDC Identity Provider in AWS
- [ ] Create IAM Role with GitHub trust policy
- [ ] Attach Terraform permissions policy
- [ ] Copy Role ARN
- [ ] Add `AWS_ROLE_ARN` secret to GitHub
- [ ] Remove `AWS_ACCESS_KEY_ID` secret (no longer needed)
- [ ] Remove `AWS_SECRET_ACCESS_KEY` secret (no longer needed)
- [ ] Workflow already updated (using OIDC by default)
- [ ] Test deployment via GitHub Actions
- [ ] Verify in CloudTrail
- [ ] Delete old IAM user access keys

---

## Additional Resources

- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AWS STS AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)

---

## Summary

**What you created**:
1. OIDC Identity Provider: `token.actions.githubusercontent.com`
2. IAM Role: `GitHubActionsRAGTerraformRole`
3. IAM Policy: `GitHubActionsRAGTerraformPolicy`

**What GitHub gets**:
- Temporary credentials (valid for a few hours)
- Scoped to your specific repository
- Automatically rotated on each workflow run
- Auditable via CloudTrail

**Security improvement**:
- ❌ Before: Long-lived access keys stored in GitHub
- ✅ After: No static credentials, OIDC tokens only
