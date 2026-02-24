# ========================
# API Access IAM User
# ========================
# Creates an IAM user for authenticated API access

resource "aws_iam_user" "api_user" {
  name = "${var.project_name}-api-user"
  path = "/api/"

  tags = merge(
    {
      Name    = "${var.project_name}-api-user"
      Purpose = "API Gateway authentication"
    },
    var.tags
  )
}

resource "aws_iam_access_key" "api_user" {
  user = aws_iam_user.api_user.name
}

# ========================
# API Access Policy
# ========================

resource "aws_iam_user_policy" "api_access" {
  name = "${var.project_name}-api-access"
  user = aws_iam_user.api_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "${var.api_execution_arn}/*/POST/chat",
          "${var.api_execution_arn}/*/POST/ingest"
        ]
      }
    ]
  })
}
