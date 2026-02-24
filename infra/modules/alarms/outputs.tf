output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.name
}

output "chat_lambda_error_alarm_name" {
  description = "Name of the chat Lambda error alarm"
  value       = aws_cloudwatch_metric_alarm.chat_lambda_errors.alarm_name
}

output "ingest_lambda_error_alarm_name" {
  description = "Name of the ingest Lambda error alarm"
  value       = aws_cloudwatch_metric_alarm.ingest_lambda_errors.alarm_name
}

output "api_5xx_error_alarm_name" {
  description = "Name of the API Gateway 5xx error alarm"
  value       = aws_cloudwatch_metric_alarm.api_gateway_5xx_errors.alarm_name
}

output "all_alarm_names" {
  description = "List of all alarm names"
  value = [
    aws_cloudwatch_metric_alarm.chat_lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.ingest_lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.chat_lambda_duration.alarm_name,
    aws_cloudwatch_metric_alarm.ingest_lambda_duration.alarm_name,
    aws_cloudwatch_metric_alarm.chat_lambda_throttles.alarm_name,
    aws_cloudwatch_metric_alarm.chat_lambda_concurrent_executions.alarm_name,
    aws_cloudwatch_metric_alarm.api_gateway_4xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.api_gateway_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.api_gateway_latency.alarm_name,
    aws_cloudwatch_metric_alarm.dynamodb_throttles.alarm_name,
  ]
}
