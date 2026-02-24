output "chat_function_name" {
  description = "Name of the chat Lambda function"
  value       = aws_lambda_function.chat.function_name
}

output "chat_function_arn" {
  description = "ARN of the chat Lambda function"
  value       = aws_lambda_function.chat.arn
}

output "chat_invoke_arn" {
  description = "Invoke ARN of the chat Lambda function"
  value       = aws_lambda_function.chat.invoke_arn
}

output "ingest_function_name" {
  description = "Name of the ingest Lambda function"
  value       = aws_lambda_function.ingest.function_name
}

output "ingest_function_arn" {
  description = "ARN of the ingest Lambda function"
  value       = aws_lambda_function.ingest.arn
}

output "ingest_invoke_arn" {
  description = "Invoke ARN of the ingest Lambda function"
  value       = aws_lambda_function.ingest.invoke_arn
}
