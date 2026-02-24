# CloudWatch Alarms - Implementation Summary

## ✅ What Was Added

### New Module: `infra/modules/alarms/`

Created a comprehensive CloudWatch alarms module with **11 alarms** monitoring all critical system components.

---

## Alarms Implemented

### **Lambda Function Health (4 alarms)**

1. **Chat Lambda Errors** - Triggers when error count > 5 in 5 minutes
2. **Ingest Lambda Errors** - Triggers when error count > 5 in 5 minutes  
3. **Chat Lambda Duration** - Warning when duration > 24s (80% of timeout)
4. **Ingest Lambda Duration** - Warning when duration > 24s (80% of timeout)

### **Lambda Performance & Scaling (2 alarms)**

5. **Chat Lambda Throttles** - Alerts when Lambda is throttled (concurrency limit hit)
6. **Chat Lambda High Concurrency** - Warning when > 50 concurrent executions (cost spike indicator)

### **API Gateway Health (3 alarms)**

7. **API Gateway 4xx Errors** - Client error rate > 20 in 5 minutes
8. **API Gateway 5xx Errors** - Server error rate > 5 in 5 minutes
9. **API Gateway Latency** - Average latency > 5 seconds

### **DynamoDB Health (1 alarm)**

10. **DynamoDB Throttling** - Alerts on throttling events (capacity exceeded)

### **Custom Cost Monitoring (1 alarm)**

11. **High Token Usage** - Triggers when token usage > 1M tokens/hour (cost spike protection)

### **Composite Alarm (1 alarm)**

12. **System Health** - Overall system status (OR condition on critical alarms)

---

## SNS Notifications

- **SNS Topic**: `rag-genai-alarms`
- **Email Subscription**: Configure in `config.yaml` (`alarms.alarm_email`)
- **All alarms** send notifications to this topic

---

## Configuration

Added to `config.yaml`:

```yaml
alarms:
  alarm_email: ""  # ← SET THIS to receive notifications
  lambda_error_threshold: 5
  lambda_duration_threshold_ms: 24000
  lambda_concurrent_executions_threshold: 50
  api_4xx_error_threshold: 20
  api_5xx_error_threshold: 5
  api_latency_threshold_ms: 5000
  token_usage_threshold_per_hour: 1000000
  enable_token_usage_alarm: true
  enable_composite_alarm: true
```

---

## Custom Metrics Integration

Enhanced `bedrock_client.py` to publish custom CloudWatch metrics:

- **TokensUsed** - Tracks token consumption per model
- **EstimatedCost** - Tracks estimated cost per API call

These metrics feed the **High Token Usage alarm**.

---

## How to Use

### 1. Set Your Email for Notifications

Edit `infra/config.yaml`:
```yaml
alarms:
  alarm_email: "your-email@example.com"
```

### 2. Deploy

```bash
cd infra
terraform init
terraform apply
```

### 3. Confirm SNS Subscription

After deployment, check your email for an SNS subscription confirmation link.

### 4. Test an Alarm

Manually trigger an alarm to test notifications:

```bash
# Trigger a test alarm from AWS Console or CLI
aws cloudwatch set-alarm-state \
  --alarm-name rag-genai-chat-lambda-errors \
  --state-value ALARM \
  --state-reason "Testing alarm notifications"
```

---

## Monitoring in AWS Console

### View All Alarms

```bash
aws cloudwatch describe-alarms --alarm-names $(terraform output -json alarm_names | jq -r '.[]')
```

### CloudWatch Dashboard (Manual Setup)

Create a dashboard with these widgets:
- Lambda error rates (both functions)
- Lambda duration (both functions)
- API Gateway request count
- Token usage over time
- Estimated cost over time

---

## Cost Impact

**SNS**: ~$0.50 per 1M email notifications (negligible unless alarms fire constantly)  
**CloudWatch Alarms**: $0.10 per alarm per month = **$1.20/month** for 12 alarms  
**Custom Metrics**: $0.30 per metric per month = **$0.60/month** for 2 custom metrics

**Total alarm cost**: ~**$2/month**

---

## What Gets Alerted

| Scenario | Alarm | Action |
|----------|-------|--------|
| Lambda crashes repeatedly | Lambda Errors | Email notification → Investigate logs |
| Lambda approaching timeout | Lambda Duration | Email notification → Optimize or increase timeout |
| API returns many 5xx errors | API Gateway 5xx | Email notification → Check Lambda health |
| User submits huge document | High Token Usage | Email notification → Review request size |
| Sudden traffic spike | High Concurrency | Email notification → Check if legitimate traffic |
| DynamoDB capacity exceeded | DynamoDB Throttles | Email notification → Increase capacity or optimize |

---

## Next Steps

1. ✅ Set `alarm_email` in config.yaml
2. ✅ Deploy with `terraform apply`
3. ✅ Confirm SNS subscription
4. ✅ Test one alarm
5. ⚠️ Consider adding **Budget Alarm** (AWS Budgets for overall spend)
6. ⚠️ Consider adding **Dead Letter Queue** for failed ingestions

---

## Files Modified

- ✅ Created: `infra/modules/alarms/main.tf`
- ✅ Created: `infra/modules/alarms/variables.tf`
- ✅ Created: `infra/modules/alarms/outputs.tf`
- ✅ Updated: `infra/main.tf` (added alarms module)
- ✅ Updated: `infra/config.yaml` (added alarms configuration)
- ✅ Updated: `infra/ouputs.tf` (added SNS topic outputs)
- ✅ Updated: `bedrock_client.py` (added CloudWatch metric publishing)
- ✅ Updated: `infra/modules/lambda/main.tf` (added PROJECT_NAME env var)

---

## Verification

After deployment, verify alarms exist:

```bash
# List all alarms
aws cloudwatch describe-alarms --query 'MetricAlarms[?starts_with(AlarmName, `rag-genai`)].AlarmName'

# Check SNS topic
terraform output sns_topic_arn

# View alarm details
aws cloudwatch describe-alarms --alarm-names rag-genai-chat-lambda-errors
```

---

**Status**: ✅ **CloudWatch Alarms - COMPLETE**

You now have production-grade monitoring with automated alerting!
