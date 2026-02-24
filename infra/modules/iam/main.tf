# ========================
# Lambda Execution Role
# ========================

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect = "Allow"
    }]
  })

  tags = merge(
    {
      Name = var.lambda_role_name
    },
    var.tags
  )
}

# ========================
# Basic Lambda Execution Policy
# ========================

resource "aws_iam_role_policy_attachment" "basic_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ========================
# Attach Custom Policies
# ========================

resource "aws_iam_role_policy_attachment" "bedrock_invoke" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = var.bedrock_policy_arn
}

resource "aws_iam_role_policy_attachment" "s3_vector_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = var.s3_policy_arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_cost_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = var.dynamodb_policy_arn
}
