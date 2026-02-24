# GitHub Environment Setup for Manual Approvals

This guide shows how to configure GitHub environment protection rules to require manual approval before Terraform apply runs.

## Setup Steps

### 1. Create Production Environment

1. Go to your repository settings:
   ```
   https://github.com/kcarterlabs/gen-ai-rag/settings/environments
   ```

2. Click **New environment**

3. Name it: `production`

4. Click **Configure environment**

### 2. Add Protection Rules

On the environment configuration page:

#### Required Reviewers

1. Check **Required reviewers**
2. Click **Add reviewers**
3. Add yourself (or other team members who can approve)
4. Set **Deployment branches**: `Selected branches` → Add `main`

#### Optional: Wait Timer

1. Check **Wait timer**
2. Set to `0` minutes (or longer if you want a delay)

### 3. Save Configuration

Click **Save protection rules**

## How It Works

### Workflow Flow

1. **Security Scan** runs on every push
2. **Terraform Plan** runs after security scan succeeds
   - Creates deployment plan
   - Uploads plan as artifact
   - Shows plan output in workflow logs
3. **⏸️ Approval Required** - Workflow pauses here
   - GitHub sends notification to reviewers
   - Reviewers can view the plan before approving
4. **Terraform Apply** runs after manual approval
   - Downloads the saved plan
   - Applies the exact plan that was reviewed
   - Updates Lambda functions
   - Shows deployment summary

### Reviewing and Approving

When a workflow reaches the approval step:

1. **GitHub sends email notification** to required reviewers

2. **Go to Actions tab**:
   ```
   https://github.com/kcarterlabs/gen-ai-rag/actions
   ```

3. **Click the waiting workflow** - You'll see:
   ```
   🟡 Waiting for approval
   1 environment requires review
   ```

4. **Review the Terraform plan**:
   - Click on the "Terraform Plan" job
   - Expand the "Terraform Plan" step
   - Review what will be created/changed/destroyed

5. **Approve or Reject**:
   - Click **Review deployments**
   - Check `production`
   - Click **Approve and deploy** or **Reject**
   - Optionally add a comment

6. **Terraform Apply runs automatically** after approval

### Example Approval Flow

```
Push to main
    ↓
Security Scan (automated)
    ↓
Terraform Plan (automated)
    ↓
📧 Email: "Deployment to production waiting for approval"
    ↓
🔍 Review plan in GitHub Actions
    ↓
✅ Click "Approve and deploy"
    ↓
Terraform Apply (automated after approval)
    ↓
🎉 Deployment complete
```

## Benefits

✅ **Human oversight** - No accidental deployments  
✅ **Plan review** - See exactly what will change before applying  
✅ **Audit trail** - GitHub tracks who approved each deployment  
✅ **Time to review** - Plan can be reviewed before approval  
✅ **Rollback safety** - Can reject if plan looks wrong  

## Cost

**Free** - GitHub environment protection is included in all plans (including free tier)

## Notifications

Reviewers get notified via:
- 📧 Email
- 🔔 GitHub notifications
- GitHub mobile app (if installed)

## Multiple Reviewers

You can require multiple approvals:
1. Add multiple reviewers in environment settings
2. Workflow waits until all approve
3. Any reviewer can reject

## Emergency Override

If you need to bypass approval:
1. **Option 1**: Use workflow_dispatch (manual trigger)
   - Go to Actions → Terraform Deploy → Run workflow
   - Manually trigger on main branch
   
2. **Option 2**: Temporarily remove protection rules
   - Only do this in emergencies
   - Remember to re-enable afterward

## Verification

Test the setup:

1. Push a change to main:
   ```bash
   git commit --allow-empty -m "test: verify approval workflow"
   git push origin main
   ```

2. Check GitHub Actions - should see:
   - ✅ Security Scan (passes)
   - ✅ Terraform Plan (passes)
   - 🟡 Terraform Apply (waiting for approval)

3. You should receive email notification

4. Approve the deployment

5. Terraform Apply should run automatically

## Troubleshooting

### "This workflow requires approval to deploy"

**Expected** - This means protection rules are working!  
Click "Review deployments" to approve.

### "You are not authorized to approve this deployment"

**Cause**: You're not listed as a required reviewer  
**Fix**: Add yourself in environment settings

### No email notification received

**Check**: 
- GitHub notification settings
- Email preferences for workflow notifications
- Spam folder

### Can't find environment settings

**Path**: Settings → Environments (in left sidebar, under Code and automation section)

## Best Practices

✅ **Always review the plan** before approving  
✅ **Add deployment comments** explaining approval reason  
✅ **Require 2+ approvers** for production  
✅ **Use branch protection** on main to prevent direct pushes  
✅ **Keep reviewer list updated** when team changes  

❌ **Don't approve without reviewing** the plan  
❌ **Don't approve if you see unexpected changes**  
❌ **Don't bypass protections** except in emergencies  

## Additional Safety Layers

Consider adding:

1. **Branch Protection Rules**:
   - Settings → Branches → Add rule for `main`
   - Require pull request reviews
   - Require status checks to pass

2. **CODEOWNERS File**:
   ```
   # .github/CODEOWNERS
   infra/** @your-username
   ```
   Requires infra changes to be reviewed

3. **Deployment Policies**:
   - No deployments on Fridays
   - No deployments during business hours
   - Maintenance window requirements

## Documentation

- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Required Reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers)
- [Deployment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules)
