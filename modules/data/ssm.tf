resource "aws_ssm_parameter" "db_host" {
  name  = "/${local.name_prefix}/app/db-host"
  type  = "String"
  value = aws_db_instance.main.address

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${local.name_prefix}/app/db-port"
  type  = "String"
  value = tostring(aws_db_instance.main.port)

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${local.name_prefix}/app/db-name"
  type  = "String"
  value = aws_db_instance.main.db_name

  tags = local.common_tags
}


resource "aws_ssm_parameter" "google_client_id" {
  name  = "/${local.name_prefix}/app/google-client-id"
  type  = "String"
  value = var.google_client_id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "sqs_category_events_queue_url" {
  name  = "/${local.name_prefix}/app/sqs-category-events-queue-url"
  type  = "String"
  value = aws_sqs_queue.category_events.url

  tags = local.common_tags
}

resource "aws_ssm_parameter" "sqs_notification_events_queue_url" {
  name  = "/${local.name_prefix}/app/sqs-notification-events-queue-url"
  type  = "String"
  value = aws_sqs_queue.notification_events.url

  tags = local.common_tags
}

resource "aws_ssm_parameter" "mongo_db_name" {
  name = "/${local.name_prefix}/app/mongo-db-name"
  type = "String"

  value = var.mongo_db_name

  tags = local.common_tags
}

resource "aws_ssm_parameter" "rds_secret_arn" {
  name  = "/${local.name_prefix}/app/rds-secret-arn"
  type  = "String"
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

resource "aws_ssm_parameter" "groq_ai_endpoint" {
  name = "/${local.name_prefix}/app/groq-ai-endpoint"
  type = "String"

  value = var.groq_ai_endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "groq_ai_model" {
  name = "/${local.name_prefix}/app/groq-ai-model"
  type = "String"

  value = var.groq_ai_model

  tags = local.common_tags
}

resource "aws_ssm_parameter" "open_router_ai_model" {
  name = "/${local.name_prefix}/app/open_router-ai-model"
  type = "String"

  value = var.open_router_ai_model

  tags = local.common_tags
}

resource "aws_ssm_parameter" "open_router_ai_endpoint" {
  name = "/${local.name_prefix}/app/open_router-ai-endpoint"
  type = "String"

  value = var.open_router_ai_endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "gemini_ai_model" {
  name = "/${local.name_prefix}/app/gemini-ai-model"
  type = "String"

  value = var.gemini_ai_model

  tags = local.common_tags
}


resource "aws_ssm_parameter" "nvidia_ai_model" {
  name = "/${local.name_prefix}/app/nvidia-ai-model"
  type = "String"

  value = var.nvidia_ai_model

  tags = local.common_tags
}

resource "aws_ssm_parameter" "nvidia_ai_endpoint" {
  name = "/${local.name_prefix}/app/nvidia-ai-endpoint"
  type = "String"

  value = var.nvidia_ai_endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "mistral_ai_model" {
  name = "/${local.name_prefix}/app/mistral-ai-model"
  type = "String"

  value = var.mistral_ai_model

  tags = local.common_tags
}

resource "aws_ssm_parameter" "mistral_ai_endpoint" {
  name = "/${local.name_prefix}/app/mistral-ai-endpoint"
  type = "String"

  value = var.mistral_ai_endpoint

  tags = local.common_tags
}


resource "aws_ssm_parameter" "cloudinary_api_key" {
  name = "/${local.name_prefix}/app/cloudinary-api-key"
  type = "String"

  value = var.cloudinary_api_key

  tags = local.common_tags
}

resource "aws_ssm_parameter" "cloudinary_cloud_name" {
  name = "/${local.name_prefix}/app/cloudinary-cloud-name"
  type = "String"

  value = var.cloudinary_cloud_name

  tags = local.common_tags
}

resource "aws_ssm_parameter" "r2_account_id" {
  name  = "/${local.name_prefix}/app/r2-account-id"
  type  = "String"
  value = var.r2_account_id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "r2_account_id" {
  name  = "/${local.name_prefix}/app/r2-access-key-id"
  type  = "String"
  value = var.r2_access_key_id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "r2_account_id" {
  name  = "/${local.name_prefix}/app/r2-secret-access-key"
  type  = "String"
  value = var.r2_secret_access_key

  tags = local.common_tags
}

resource "aws_ssm_parameter" "r2_bucket" {
  name  = "/${local.name_prefix}/app/r2-bucket"
  type  = "String"
  value = var.r2_bucket

  tags = local.common_tags
}

resource "aws_ssm_parameter" "ws_allowed_origins" {
  name  = "/${local.name_prefix}/app/ws-allowed-origins"
  type  = "String"
  value = var.ws_allowed_origins

  tags = local.common_tags
}

# --- Real secrets, SSM SecureString ----------------------------------
# Migrated off Secrets Manager - none of these ever used rotation, cross-
# account sharing, or >4KB values, so Secrets Manager bought nothing here
# beyond ~$0.40/secret/month. Values created manually via
# `aws ssm put-parameter --type SecureString`, never Terraform-managed -
# same rule as before, just a different backing service. The app fetches
# these by name directly (same ssm:GetParameter(s) call it already makes
# for db-host etc, WithDecryption: true) - no more ARN-indirection layer,
# since there's nothing to "discover" the way there was with Secrets
# Manager's separately-generated ARNs.

data "aws_ssm_parameter" "jwt_secret" {
  name            = var.jwt_secret_name
  with_decryption = false # only need the ARN here, not the value itself
}

data "aws_ssm_parameter" "mongo_db_uri_secret" {
  name            = var.mongo_db_uri_secret_name
  with_decryption = false
}

data "aws_ssm_parameter" "groq_ai_secret" {
  name            = var.groq_ai_secret_name
  with_decryption = false
}

data "aws_ssm_parameter" "gemini_ai_secret" {
  name            = var.gemini_ai_secret_name
  with_decryption = false
}

data "aws_ssm_parameter" "open_router_ai_secret" {
  name            = var.open_router_ai_secret_name
  with_decryption = false
}

data "aws_ssm_parameter" "mistral_ai_secret" {
  name            = var.mistral_ai_secret_name
  with_decryption = false
}

data "aws_ssm_parameter" "nvidia_ai_secret" {
  name            = var.nvidia_ai_secret_name
  with_decryption = false
}

data "aws_ssm_parameter" "cloudinary_api_secret" {
  name            = var.cloudinary_api_secret_name
  with_decryption = false
}


resource "aws_iam_policy" "app_config_read" {
  name        = "${local.name_prefix}-app-config-read"
  description = "Read-only access to plain app runtime config in SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = [
          aws_ssm_parameter.db_host.arn,
          aws_ssm_parameter.db_port.arn,
          aws_ssm_parameter.db_name.arn,
          aws_ssm_parameter.google_client_id.arn,
          aws_ssm_parameter.sqs_category_events_queue_url.arn,
          aws_ssm_parameter.sqs_notification_events_queue_url.arn,
          aws_ssm_parameter.mongo_db_name.arn,
          aws_ssm_parameter.groq_ai_model.arn,
          aws_ssm_parameter.groq_ai_endpoint.arn,
          aws_ssm_parameter.nvidia_ai_model.arn,
          aws_ssm_parameter.nvidia_ai_endpoint.arn,
          aws_ssm_parameter.open_router_ai_model.arn,
          aws_ssm_parameter.open_router_ai_endpoint.arn,
          aws_ssm_parameter.mistral_ai_model.arn,
          aws_ssm_parameter.mistral_ai_endpoint.arn,
          aws_ssm_parameter.gemini_ai_model.arn,
          aws_ssm_parameter.rds_secret_arn.arn,
          aws_ssm_parameter.ws_allowed_origins.arn,

        ]
      }
    ]
  })

  tags = local.common_tags
}

# Kept as three separate, narrowly-scoped policies rather than folding
# these into app_config_read - real secrets, worth keeping a tighter blast
# radius even though the mechanism (SSM GetParameter) is now identical to
# the plain-config policy above.

resource "aws_iam_policy" "jwt_secret_read" {
  name        = "${local.name_prefix}-jwt-secret-read"
  description = "Read-only access to the shared JWT signing secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.jwt_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "mongo_secret_read" {
  name        = "${local.name_prefix}-mongo-secret-read"
  description = "Read-only access to the MongoDB Atlas connection URI"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.mongo_db_uri_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "groq_ai_secret_read" {
  name        = "${local.name_prefix}-groq-ai-secret-read"
  description = "Read-only access to the Groq API Key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.groq_ai_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "gemini_ai_secret_read" {
  name        = "${local.name_prefix}-gemini-ai-secret-read"
  description = "Read-only access to the Gemini API Key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.gemini_ai_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "nvidia_ai_secret_read" {
  name        = "${local.name_prefix}-nvidia-ai-secret-read"
  description = "Read-only access to the Nvidia API Key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.nvidia_ai_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "cloudinary_api_secret_read" {
  name        = "${local.name_prefix}-cloudinary-api-secret-read"
  description = "Read-only access to the Cloudinary API Secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.cloudinary_api_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}


resource "aws_iam_policy" "open_router_ai_secret_read" {
  name        = "${local.name_prefix}-open_router-ai-secret-read"
  description = "Read-only access to the OpenRouter API Key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.open_router_ai_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "mistral_ai_secret_read" {
  name        = "${local.name_prefix}-mistral-ai-secret-read"
  description = "Read-only access to the Mistral API Key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = data.aws_ssm_parameter.mistral_ai_secret.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}


