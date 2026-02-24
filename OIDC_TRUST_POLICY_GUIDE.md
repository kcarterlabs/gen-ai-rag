# OIDC Trust Policy Security Options

## The AWS Warning Explained

When you use a wildcard (`*`) in the GitHub OIDC trust policy:

```json
"token.actions.githubusercontent.com:sub": "repo:kcarterlabs/gen-ai-rag:*"
```

AWS warns:
> "Using a wildcard (*) can allow requests from more sources than you intended."

This is because `*` matches:
- All branches: `repo:kcarterlabs/gen-ai-rag:ref:refs/heads/main`, `ref:refs/heads/develop`, etc.
- All pull requests: `repo:kcarterlabs/gen-ai-rag:pull_request`
- All tags: `repo:kcarterlabs/gen-ai-rag:ref:refs/tags/*`
- All environments: `repo:kcarterlabs/gen-ai-rag:environment:production`

## Should You Care?

**The workflow already protects you!**

Even with the wildcard trust policy, your GitHub Actions workflow has this protection:

```yaml
- name: Terraform Apply
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: terraform apply -auto-approve tfplan
```

This means:
- ✅ **Terraform plan** can run on any branch/PR (read-only, safe)
- ✅ **Terraform apply** ONLY runs on main branch pushes (write operations)

So the wildcard allows PRs to preview changes, but only main can deploy.

## Security Options

### Option 1: Keep Wildcard (Workflow-Protected) ⚡ Easiest

**Trust Policy**:
```json
"StringLike": {
  "token.actions.githubusercontent.com:sub": "repo:kcarterlabs/gen-ai-rag:*"
}
```

**Pros**:
- ✅ PRs can run `terraform plan` for review
- ✅ Workflow conditions prevent unauthorized deploys
- ✅ Faster PR feedback loop

**Cons**:
- ⚠️ AWS shows warning in console
- ⚠️ Requires trust in workflow conditions

**Best for**: Teams that want PR plan previews

---

### Option 2: Main Branch Only (Most Secure) 🔒 Recommended

**Trust Policy**:
```json
"StringEquals": {
  "token.actions.githubusercontent.com:sub": "repo:kcarterlabs/gen-ai-rag:ref:refs/heads/main"
}
```

**Pros**:
- ✅ No AWS warning
- ✅ Maximum security - only main branch
- ✅ Clear, explicit trust boundary

**Cons**:
- ❌ PRs cannot run `terraform plan`
- ❌ Must merge to main to see plan

**Best for**: Production environments, high-security requirements

---

### Option 3: Specific Branches + PRs (Balanced) ⚖️ Best Practice

**Trust Policy**:
```json
"ForAnyValue:StringLike": {
  "token.actions.githubusercontent.com:sub": [
    "repo:kcarterlabs/gen-ai-rag:ref:refs/heads/main",
    "repo:kcarterlabs/gen-ai-rag:ref:refs/heads/develop",
    "repo:kcarterlabs/gen-ai-rag:pull_request"
  ]
}
```

**Pros**:
- ✅ No AWS warning
- ✅ PRs can run `terraform plan`
- ✅ Explicitly lists allowed sources
- ✅ Workflow still controls apply

**Cons**:
- ⚠️ Must update policy to add new branches

**Best for**: Most teams - balances security and usability

---

## How to Change (Automated)

```bash
cd infra/oidc-setup

# Option 1: Main branch only (most secure)
terraform apply -var="trust_policy_mode=main-only"

# Option 2: All branches (workflow-protected)
terraform apply -var="trust_policy_mode=all-branches"

# Option 3: Specific branches + PRs (balanced)
terraform apply -var="trust_policy_mode=specific-branches" \
  -var='allowed_branches=["main","develop","staging"]'
```

## How to Change (Manual Console)

1. Go to **IAM Console** → **Roles** → `GitHubActionsRAGTerraformRole`
2. Click **Trust relationships** tab
3. Click **Edit trust policy**
4. Replace with your chosen option from above
5. Click **Update policy**

## Recommendation by Use Case

| Use Case | Recommended Mode | Reasoning |
|----------|-----------------|-----------|
| Production infrastructure | `main-only` | Maximum security, no wildcards |
| Development infrastructure | `specific-branches` | PR previews + explicit control |
| Small team / personal project | `all-branches` | Flexibility, workflow-protected |
| Multi-environment (dev/staging/prod) | `specific-branches` per environment | Separate roles per environment |

## What We Did

The automated setup defaults to **`main-only`** because:
- ✅ Eliminates the AWS warning
- ✅ Follows principle of least privilege
- ✅ Production-ready out of the box

But you can easily change to `specific-branches` if you want PR plan previews:

```bash
terraform apply -var="trust_policy_mode=specific-branches"
```

## Additional Layer: GitHub Environment Protection

For extra security, configure GitHub environment protection rules:

1. Go to: https://github.com/kcarterlabs/gen-ai-rag/settings/environments
2. Create environment: `production`
3. Add protection rules:
   - ✅ Required reviewers
   - ✅ Restrict branches to `main`
   - ✅ Wait timer before deployment

Then in workflow:
```yaml
environment: production  # Requires approval
```

This adds human approval even if OIDC trust policy allows access.

## Summary

**The AWS warning is about defense-in-depth, not a critical vulnerability.**

Your options:
1. **Ignore it** - Workflow already protects you ⚡
2. **Use `main-only`** - Eliminates warning, maximum security 🔒
3. **Use `specific-branches`** - Best of both worlds ⚖️

For this project, we default to **`main-only`** for security, but you can change it anytime with one command.
