variable "name_prefix" {
  description = "Prefix applied to every resource name/tag in this module."
  type        = string
}

variable "tags" {
  description = "Common tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}

variable "private_subnet_ids" {
  description = "Both private subnet IDs (2 AZs), for the RDS DB subnet group. RDS itself only actually runs in one AZ - the second subnet is present purely to satisfy AWS's subnet-group AZ-count requirement."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) == 2
    error_message = "Expected exactly 2 private subnet IDs (one per AZ)."
  }
}

variable "rds_sg_id" {
  description = "Security group ID (from the network module) that already scopes Postgres ingress to Core/Chat/Worker only."
  type        = string
}

variable "db_engine_version" {
  description = "Postgres engine version. Must be >= 15.2 for pgvector support."
  type        = string
  default     = "16.9"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "EBS storage type backing the RDS instance."
  type        = string
  default     = "gp3"
}

variable "db_storage_encrypted" {
  description = "Whether to encrypt storage at rest (AWS-managed KMS key)."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Initial database name created on the instance."
  type        = string
}

variable "compute_az" {
  description = "AZ where applications actually run - keep RDS in the same AZ as the app tier."
  type        = string
}

variable "db_backup_retention_days" {
  description = "Automated backup retention period, in days. 0 disables automated backups entirely."
  type        = number
  default     = 1
}

variable "db_skip_final_snapshot" {
  description = "Skip taking a final snapshot on destroy."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Prevent accidental terraform destroy of the RDS instance."
  type        = bool
  default     = false
}

variable "db_apply_immediately" {
  description = "Apply modifications immediately instead of during the next maintenance window."
  type        = bool
  default     = true
}

variable "chat_events_queue_name" {
  description = "Name of the Chat -> Notification queue"
  type        = string
  default     = "chat-events"
}

variable "category_events_queue_name" {
  description = "Name of the Core -> Categorization Worker queue."
  type        = string
  default     = "category-events"
}

variable "notification_events_queue_name" {
  description = "Name of the Categorization Worker -> Notification Lambda queue."
  type        = string
  default     = "notification-events"
}

variable "sqs_visibility_timeout_seconds" {
  description = "Visibility timeout for both queues."
  type        = number
  default     = 90
}

variable "sqs_message_retention_seconds" {
  description = "How long an unconsumed message stays in the queue before being dropped."
  type        = number
  default     = 345600 # 4 days, SQS default
}

# Runtime config (SSM)

variable "google_client_id" {
  description = "OAuth client ID for Google Sign-In."
  type        = string
}

variable "jwt_secret_name" {
  description = "Name of the SSM SecureString parameter holding the shared JWT signing secret (migrated from Secrets Manager - free tier, no rotation was in use)."
  type        = string
}

variable "mongo_db_name" {
  description = "Name of the database in Mongo."
  type        = string
}

variable "groq_ai_endpoint" {
  type = string
}

variable "groq_ai_model" {
  type = string
}

variable "mistral_ai_endpoint" {
  type = string
}

variable "open_router_ai_endpoint" {
  type = string
}

variable "open_router_ai_model" {
  type = string
}

variable "gemini_ai_model" {
  type = string
}

variable "nvidia_ai_endpoint" {
  type = string
}

variable "nvidia_ai_model" {
  type = string
}

variable "mistral_ai_model" {
  type = string
}

variable "cloudinary_cloud_name" {
  type = string
}

variable "cloudinary_api_key" {
  type = string
}

variable "r2_account_id" {
  type = string
}

variable "r2_access_key_id" {
  type = string
}

variable "r2_secret_access_key" {
  type = string
}

variable "r2_bucket" {
  type = string
}

variable "ws_allowed_origins" {
  description = "Origins allowed to establish WebSocket connections."
  type        = string
}

variable "mongo_db_uri_secret_name" {
  description = "Name of the SSM SecureString parameter holding the MongoDB Atlas connection URI (migrated from Secrets Manager)."
  type        = string
}

variable "groq_ai_secret_name" {
  description = "Name of the SSM SecureString parameter holding the Groq API Key (migrated from Secrets Manager)."
  type        = string
}

variable "gemini_ai_secret_name" {
  description = "Name of the SSM SecureString parameter holding the Gemini API Key (migrated from Secrets Manager)."
  type        = string
}

variable "open_router_ai_secret_name" {
  description = "Name of the SSM SecureString parameter holding the OpenRouter API Key (migrated from Secrets Manager)."
  type        = string
}

variable "nvidia_ai_secret_name" {
  description = "Name of the SSM SecureString parameter holding the Nvidia API Key (migrated from Secrets Manager)."
  type        = string
}

variable "mistral_ai_secret_name" {
  description = "Name of the SSM SecureString parameter holding the Mistral API Key (migrated from Secrets Manager)."
  type        = string
}

variable "cloudinary_api_secret_name" {
  description = "Name of the SSM SecureString parameter holding the Cloudinary API Secret (migrated from Secrets Manager)."
  type        = string
}
