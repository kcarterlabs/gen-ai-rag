# ========================
# Chat Lambda Function
# ========================

resource "aws_lambda_function" "chat" {
  function_name = "${var.project_name}-chat"
  role          = var.iam_role_arn
  handler       = "chat_handler.lambda_handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = var.deployment_package_path
  source_code_hash = filebase64sha256(var.deployment_package_path)

  environment {
    variables = merge(
      var.environment_variables,
      {
        PROJECT_NAME = var.project_name
      }
    )
  }

  tags = merge(
    {
      Name = "${var.project_name}-chat"
      Type = "chat-handler"
    },
    var.tags
  )
}

# CloudWatch Log Group for Chat Lambda
resource "aws_cloudwatch_log_group" "chat" {
  name              = "/aws/lambda/${aws_lambda_function.chat.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name = "${var.project_name}-chat-logs"
    },
    var.tags
  )
}

# ========================
# Ingest Lambda Function
# ========================

resource "aws_lambda_function" "ingest" {
  function_name = "${var.project_name}-ingest"
  role          = var.iam_role_arn
  handler       = "ingest_handler.lambda_handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = var.deployment_package_path
  source_code_hash = filebase64sha256(var.deployment_package_path)

  environment {
    variables = merge(
      var.environment_variables,
      {
        PROJECT_NAME = var.project_name
      }
    )
  }

  tags = merge(
    {
      Name = "${var.project_name}-ingest"
      Type = "ingest-handler"
    },
    var.tags
  )
}

# CloudWatch Log Group for Ingest Lambda
resource "aws_cloudwatch_log_group" "ingest" {
  name              = "/aws/lambda/${aws_lambda_function.ingest.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name = "${var.project_name}-ingest-logs"
    },
    var.tags
  )
}

# ========================
# S3 Event Trigger for Ingest
# ========================

resource "aws_s3_bucket_notification" "ingest_trigger" {
  bucket = var.vector_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ingest.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.vector_bucket_arn
}
