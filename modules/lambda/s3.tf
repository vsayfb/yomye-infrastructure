data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "deployments" {
  bucket = "${local.name_prefix}-lambda-deployments-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-deployments"
  })
}

resource "aws_s3_bucket_versioning" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 2
    }
  }
}

resource "aws_s3_object" "lambda_bootstrap" {
  bucket = aws_s3_bucket.deployments.id
  key    = var.lambda_deployment_s3_key

  source = "${path.module}/bootstrap/placeholder.zip"

  # Bootstrap artifact only. The real Lambda package is uploaded by the
  # deployment pipeline, so Terraform does not track object content changes.
  lifecycle {
    ignore_changes = [etag]
  }
}
