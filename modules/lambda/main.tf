locals {
  name_prefix = var.name_prefix
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "lambda"
  })
}

data "aws_ssm_parameter" "firebase_credentials" {
  name            = var.firebase_credentials_secret_name
  with_decryption = false # only need the ARN here, not the value itself
}

resource "aws_lambda_function" "notification" {
  function_name = "${local.name_prefix}-notification-lambda"

  s3_bucket = aws_s3_object.lambda_bootstrap.bucket
  s3_key    = aws_s3_object.lambda_bootstrap.key

  runtime = var.runtime
  handler = var.handler

  role        = aws_iam_role.lambda.arn
  memory_size = var.memory_size
  timeout     = var.timeout_seconds

  vpc_config {
    subnet_ids         = [var.compute_subnet_id]
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      # SSM parameter NAME now, not a Secrets Manager ARN - the Lambda
      # fetches this directly via ssm:GetParameter(name, WithDecryption).
      FIREBASE_CREDENTIALS_PARAMETER_NAME = data.aws_ssm_parameter.firebase_credentials.name
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-notification-lambda" })

  lifecycle {
    ignore_changes = [s3_key, source_code_hash]
  }
}

resource "aws_lambda_event_source_mapping" "notification_events" {
  event_source_arn = var.notification_events_queue_arn
  function_name    = aws_lambda_function.notification.arn
  batch_size       = var.sqs_batch_size
  enabled          = true
}
