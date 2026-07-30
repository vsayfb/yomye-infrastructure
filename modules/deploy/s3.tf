data "aws_caller_identity" "current" {}

locals {
  name_prefix = var.name_prefix
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "deploy"
  })

  core_chat_name_tag = coalesce(var.core_chat_instance_name_tag, "${local.name_prefix}-core-chat")
  worker_name_tag    = coalesce(var.worker_instance_name_tag, "${local.name_prefix}-worker")
}

resource "aws_s3_bucket" "app_deployments" {
  bucket = "${local.name_prefix}-app-deployments-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-deployments"
  })
}

resource "aws_s3_bucket_versioning" "app_deployments" {
  bucket = aws_s3_bucket.app_deployments.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_deployments" {
  bucket = aws_s3_bucket.app_deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "app_deployments" {
  bucket = aws_s3_bucket.app_deployments.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 2
    }
  }
}

