# ========================
# Bedrock Invoke Policy
# ========================

resource "aws_iam_policy" "bedrock_invoke" {
  name        = "${var.project_name}-bedrock-invoke"
  description = "Allow Lambda to invoke Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v1",
          "arn:aws:bedrock:${var.region}::foundation-model/meta.llama3-8b-instruct-v1:0"
        ]
      }
    ]
  })
}

# ========================
# S3 Vector Store Policy
# ========================

resource "aws_iam_policy" "s3_vector_access" {
  name        = "${var.project_name}-s3-vector-access"
  description = "Allow Lambda to read/write vectors to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.vector_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.vector_bucket_arn
      }
    ]
  })
}

# ========================
# DynamoDB Cost Tracking Policy
# ========================

resource "aws_iam_policy" "dynamodb_cost_access" {
  name        = "${var.project_name}-dynamodb-cost-access"
  description = "Allow Lambda to write cost data to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Resource = var.cost_table_arn
      }
    ]
  })
}
