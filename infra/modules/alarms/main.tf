# ========================
# SNS Topic for Alarm Notifications
# ========================

resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"

  tags = merge(
    {
      Name = "${var.project_name}-alarms"
    },
    var.tags
  )
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ========================
# Lambda Error Rate Alarms
# ========================

resource "aws_cloudwatch_metric_alarm" "chat_lambda_errors" {
  alarm_name          = "${var.project_name}-chat-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Chat Lambda error rate is too high"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.chat_lambda_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ingest_lambda_errors" {
  alarm_name          = "${var.project_name}-ingest-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Ingest Lambda error rate is too high"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.ingest_lambda_name
  }

  tags = var.tags
}

# ========================
# Lambda Duration Alarms
# ========================

resource "aws_cloudwatch_metric_alarm" "chat_lambda_duration" {
  alarm_name          = "${var.project_name}-chat-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold_ms
  alarm_description   = "Chat Lambda duration is too high (approaching timeout)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.chat_lambda_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ingest_lambda_duration" {
  alarm_name          = "${var.project_name}-ingest-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold_ms
  alarm_description   = "Ingest Lambda duration is too high (approaching timeout)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.ingest_lambda_name
  }

  tags = var.tags
}

# ========================
# Lambda Throttling Alarms
# ========================

resource "aws_cloudwatch_metric_alarm" "chat_lambda_throttles" {
  alarm_name          = "${var.project_name}-chat-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Chat Lambda is being throttled (concurrency limit reached)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.chat_lambda_name
  }

  tags = var.tags
}

# ========================
# Lambda Concurrent Executions Alarm
# ========================

resource "aws_cloudwatch_metric_alarm" "chat_lambda_concurrent_executions" {
  alarm_name          = "${var.project_name}-chat-lambda-high-concurrency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.lambda_concurrent_executions_threshold
  alarm_description   = "Chat Lambda concurrent executions are high (potential cost spike)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.chat_lambda_name
  }

  tags = var.tags
}

# ========================
# API Gateway Error Rate Alarms
# ========================

resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  alarm_name          = "${var.project_name}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.api_4xx_error_threshold
  alarm_description   = "API Gateway 4xx error rate is high (client errors)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${var.project_name}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.api_5xx_error_threshold
  alarm_description   = "API Gateway 5xx error rate is high (server errors)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = var.tags
}

# ========================
# API Gateway Latency Alarm
# ========================

resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  alarm_name          = "${var.project_name}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "IntegrationLatency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = var.api_latency_threshold_ms
  alarm_description   = "API Gateway latency is too high"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = var.tags
}

# ========================
# DynamoDB Throttling Alarm
# ========================

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "DynamoDB is experiencing throttling (consider increasing capacity)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = var.dynamodb_table_name
  }

  tags = var.tags
}

# ========================
# Custom Metric: High Token Usage Alarm
# ========================

# This alarm triggers on custom metrics logged from Lambda
# You'll need to publish these metrics in bedrock_client.py

resource "aws_cloudwatch_metric_alarm" "high_token_usage" {
  count               = var.enable_token_usage_alarm ? 1 : 0
  alarm_name          = "${var.project_name}-high-token-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TokensUsed"
  namespace           = var.project_name
  period              = 3600 # 1 hour
  statistic           = "Sum"
  threshold           = var.token_usage_threshold_per_hour
  alarm_description   = "Token usage per hour exceeded threshold (potential cost spike)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# ========================
# Composite Alarm: System Health
# ========================

resource "aws_cloudwatch_composite_alarm" "system_health" {
  count             = var.enable_composite_alarm ? 1 : 0
  alarm_name        = "${var.project_name}-system-health"
  alarm_description = "Overall system health (multiple components failing)"

  alarm_actions = [aws_sns_topic.alarms.arn]

  actions_suppressor {
    alarm            = aws_cloudwatch_metric_alarm.chat_lambda_errors.alarm_name
    extension_period = 300
    wait_period      = 60
  }

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.chat_lambda_errors.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.api_gateway_5xx_errors.alarm_name})"

  tags = var.tags
}
