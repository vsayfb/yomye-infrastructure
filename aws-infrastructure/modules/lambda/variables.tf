variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Networking inputs

variable "compute_subnet_id" {
  description = "Private subnet (AZ index 0) the Lambda's ENIs attach to - same AZ as the rest of real compute."
  type        = string
}

variable "lambda_sg_id" {
  type = string
}

# Data inputs

variable "notification_events_queue_arn" {
  type = string
}

variable "lambda_sqs_consume_policy_arn" {
  type = string
}

variable "rds_secret_read_policy_arn" {
  type = string
}

# Firebase

variable "firebase_credentials_secret_name" {
  description = "Name of the Secrets Manager secret holding the Firebase service account JSON blob."
  type        = string
}

# Function config

variable "lambda_deployment_s3_key" {
  description = "S3 key of the deployment package, within this module's own dedicated deployments bucket."
  type        = string
  default     = "notification-lambda/bootstrap.zip"
}


variable "runtime" {
  description = "provided.al2023 - Go compiles to a custom-runtime binary named 'bootstrap'."
  type        = string
  default     = "provided.al2023"
}

variable "handler" {
  type    = string
  default = "bootstrap"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "timeout_seconds" {
  description = "Must stay under the SQS queue's visibility_timeout_seconds (90s in data/)."
  type        = number
  default     = 60
}

variable "sqs_batch_size" {
  description = "Max messages per Lambda invocation from the event source mapping."
  type        = number
  default     = 10
}

variable "app_config_read_policy_arn" {
  description = "From data/ - Lambda writes to RDS."
  type        = string
}

variable "observability_read_policy_arn" {
  description = "From observability only needed if Lambda ships its own telemetry rather than relying on CloudWatch alone."
  type        = string
}
