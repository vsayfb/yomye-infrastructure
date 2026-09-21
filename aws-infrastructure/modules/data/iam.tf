resource "aws_iam_policy" "core_sqs_produce" {
  name        = "${local.name_prefix}-core-sqs-produce"
  description = "Core: send-only access to category-events"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sqs:SendMessage"]
        Resource = [
          aws_sqs_queue.category_events.arn,
          aws_sqs_queue.notification_events.arn,
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "worker_sqs_access" {
  name        = "${local.name_prefix}-worker-sqs-access"
  description = "Categorization Worker: consume category-events, produce notification-events"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.category_events.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.notification_events.arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "lambda_sqs_consume" {
  name        = "${local.name_prefix}-lambda-sqs-consume"
  description = "Notification Lambda: consume-only access to notification-events"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.notification_events.arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "rds_secret_read" {
  name        = "${local.name_prefix}-rds-secret-read"
  description = "Read-only access to the RDS master user secret in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_db_instance.main.master_user_secret[0].secret_arn
      }
    ]
  })

  tags = local.common_tags
}
