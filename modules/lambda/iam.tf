resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-notification-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}


resource "aws_iam_role_policy_attachment" "lambda_sqs_consume" {
  role       = aws_iam_role.lambda.name
  policy_arn = var.lambda_sqs_consume_policy_arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds_secret" {
  role       = aws_iam_role.lambda.name
  policy_arn = var.rds_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "lambda_app_config_read" {
  role       = aws_iam_role.lambda.name
  policy_arn = var.app_config_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "lambda_observability_read" {
  role       = aws_iam_role.lambda.name
  policy_arn = var.observability_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_firebase_secret_read" {
  name = "${local.name_prefix}-lambda-firebase-secret-read"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = data.aws_ssm_parameter.firebase_credentials.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}
