output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.rag_api.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.rag_api.api_endpoint
}

output "chat_url" {
  description = "Full URL for the chat endpoint"
  value       = "${aws_apigatewayv2_api.rag_api.api_endpoint}/chat"
}

output "api_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_apigatewayv2_api.rag_api.execution_arn
}
