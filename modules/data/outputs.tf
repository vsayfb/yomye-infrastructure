output "compute_az" {
  value = var.compute_az
}

# RDS

output "rds_endpoint" {
  description = "Connection endpoint (host:port), for DATABASE_URL construction."
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Host only, no port."
  value       = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "rds_db_name" {
  value = aws_db_instance.main.db_name
}

output "rds_master_username" {
  description = "Auto-generated master username."
  value       = local.db_master_username
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN holding the AWS-generated master password."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

# SQS

output "category_events_queue_url" {
  value = aws_sqs_queue.category_events.url
}

output "category_events_queue_arn" {
  value = aws_sqs_queue.category_events.arn
}

output "notification_events_queue_url" {
  value = aws_sqs_queue.notification_events.url
}

output "notification_events_queue_arn" {
  value = aws_sqs_queue.notification_events.arn
}

# IAM

output "core_sqs_produce_policy_arn" {
  value = aws_iam_policy.core_sqs_produce.arn
}

output "worker_sqs_access_policy_arn" {
  value = aws_iam_policy.worker_sqs_access.arn
}

output "lambda_sqs_consume_policy_arn" {
  value = aws_iam_policy.lambda_sqs_consume.arn
}

output "rds_secret_read_policy_arn" {
  value = aws_iam_policy.rds_secret_read.arn
}

# Runtime config (SSM)

output "db_host_parameter_name" {
  value = aws_ssm_parameter.db_host.name
}

output "db_port_parameter_name" {
  value = aws_ssm_parameter.db_port.name
}

output "db_name_parameter_name" {
  value = aws_ssm_parameter.db_name.name
}

output "google_client_id_parameter_name" {
  value = aws_ssm_parameter.google_client_id.name
}

output "sqs_category_events_queue_url_parameter_name" {
  value = aws_ssm_parameter.sqs_category_events_queue_url.name
}

output "sqs_notification_events_queue_url_parameter_name" {
  value = aws_ssm_parameter.sqs_notification_events_queue_url.name
}

output "app_config_read_policy_arn" {
  value = aws_iam_policy.app_config_read.arn
}

output "jwt_secret_read_policy_arn" {
  value = aws_iam_policy.jwt_secret_read.arn
}

output "mongodb_uri_secret_read_policy_arn" {
  value = aws_iam_policy.mongo_secret_read.arn
}

output "groq_ai_secret_read_policy_arn" {
  value = aws_iam_policy.groq_ai_secret_read.arn
}

output "gemini_ai_secret_read_policy_arn" {
  value = aws_iam_policy.gemini_ai_secret_read.arn
}
output "qwen_ai_secret_read_policy_arn" {
  value = aws_iam_policy.qwen_ai_secret_read.arn
}

output "nvidia_ai_secret_read_policy_arn" {
  value = aws_iam_policy.nvidia_ai_secret_read.arn
}

output "cloudinary_api_secret_read_policy_arn" {
  value = aws_iam_policy.cloudinary_api_secret_read.arn
}

