variable "project_id" {
  description = "Existing Google Cloud project in which this environment will be created. Use one GCP project per environment."
  type        = string
}

variable "region" {
  description = "Primary Google Cloud region. europe-west3 is Frankfurt, matching the AWS eu-central-1 deployment geography."
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "Single compute zone for Core/Chat, Worker, and Cloud SQL, mirroring the current AWS layout where real compute and RDS run in one AZ."
  type        = string
  default     = "europe-west3-a"
}

variable "name_prefix" {
  type    = string
  default = "yevmiye"
}

variable "api_domain" {
  description = "Public DNS hostname for the HTTPS application load balancer."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$", var.api_domain))
    error_message = "api_domain must be a hostname without a scheme, port, or path."
  }
}

variable "environment" {
  description = "Application environment label. This Terraform root deploys the GCP production environment."
  type        = string
  default     = "production"

  validation {
    condition     = var.environment == "production"
    error_message = "This Terraform root is intentionally production-only."
  }
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "network_cidr" {
  type    = string
  default = "10.20.0.0/20"
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs. Disabled by default to match the current AWS VPC, which does not enable flow logs."
  type        = bool
  default     = false
}

variable "enable_nat_logging" {
  description = "Enable Cloud NAT error logging. Disabled by default to match the current self-managed AWS NAT instance logging posture."
  type        = bool
  default     = false
}

variable "enable_load_balancer_logging" {
  description = "Enable load balancer request logging. Disabled by default because the current AWS ALB has no access logs configured."
  type        = bool
  default     = false
}

variable "core_port" {
  type    = number
  default = 8080
}

variable "chat_port" {
  type    = number
  default = 8081
}

variable "core_chat_machine_type" {
  description = "Closest GCP capacity match to the AWS t3.small Core/Chat host (2 GiB RAM)."
  type        = string
  default     = "e2-small"
}

variable "worker_machine_type" {
  description = "Closest GCP capacity match to the AWS t3.small Worker host (2 GiB RAM)."
  type        = string
  default     = "e2-small"
}

variable "core_chat_boot_disk_size_gb" {
  description = "GCP boot disk size for Core/Chat. 10 GB is the practical GCP equivalent of the AWS 8 GB root volume."
  type        = number
  default     = 10
}

variable "worker_boot_disk_size_gb" {
  description = "GCP boot disk size for Worker. 10 GB mirrors the small AWS root volume while leaving room for the current Ollama model."
  type        = number
  default     = 10
}

variable "db_name" {
  type    = string
  default = "yevmiye"
}

variable "db_user" {
  description = "Optional explicit Cloud SQL application username. When null, Terraform generates an AWS-style yevmiye_<suffix> username."
  type        = string
  default     = null
}

variable "db_tier" {
  description = "Closest Cloud SQL memory match to AWS db.t4g.micro. Shared-core tiers are intended for small/test environments, matching the current AWS staging footprint."
  type        = string
  default     = "db-g1-small"
}

variable "db_disk_size_gb" {
  type    = number
  default = 20
}

variable "db_deletion_protection" {
  description = "Disabled by default to match the current AWS RDS setting."
  type        = bool
  default     = false
}

variable "db_backup_retention_count" {
  description = "Number of automated backups retained. The AWS RDS configuration retains one day."
  type        = number
  default     = 1
}

variable "db_transaction_log_retention_days" {
  description = "Cloud SQL PITR transaction-log retention, aligned with the one-day AWS RDS automated-backup window."
  type        = number
  default     = 1
}

variable "notification_bootstrap_image" {
  description = "Initial public image used only to create Cloud Run; GitHub owns subsequent notification image updates."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "notification_delivery_enabled" {
  description = "Enable Pub/Sub push only after the real notification image has been deployed."
  type        = bool
  default     = false
}

variable "notification_timeout" {
  description = "Maximum request duration for a Pub/Sub delivery, matching the AWS Lambda 60 second timeout."
  type        = string
  default     = "60s"
}

variable "notification_deletion_protection" {
  description = "Disabled by default to match the current AWS Lambda lifecycle posture."
  type        = bool
  default     = false
}

variable "github_org" {
  type = string
}

variable "github_repos" {
  type = set(string)
}

variable "github_environment" {
  type    = string
  default = "production"

  validation {
    condition     = var.github_environment == "production"
    error_message = "The production deployment identity requires the GitHub production environment."
  }
}

variable "google_client_id" {
  type = string
}

variable "mongo_db_name" {
  type    = string
  default = "yevmiye"
}

variable "ws_allowed_origins" {
  type = string
}

variable "grafana_cloud_opamp_endpoint" {
  type = string
}

variable "grafana_cloud_otlp_endpoint" {
  type = string
}

variable "otel_collector_version" {
  type    = string
  default = "0.156.0"
}

variable "groq_ai_endpoint" {
  type    = string
  default = ""
}

variable "groq_ai_model" {
  type    = string
  default = ""
}

variable "gemini_model" {
  type    = string
  default = ""
}

variable "open_router_ai_endpoint" {
  type    = string
  default = ""
}

variable "open_router_ai_model" {
  type    = string
  default = ""
}

variable "nvidia_ai_endpoint" {
  type    = string
  default = ""
}

variable "nvidia_ai_model" {
  type    = string
  default = ""
}

variable "mistral_ai_endpoint" {
  type    = string
  default = ""
}

variable "mistral_ai_model" {
  type    = string
  default = ""
}

variable "cloudinary_api_key" {
  type    = string
  default = ""
}

variable "cloudinary_cloud_name" {
  type    = string
  default = ""
}

variable "r2_account_id" {
  type    = string
  default = ""
}

variable "r2_access_key_id" {
  description = "Cloudflare R2 access key ID, matching the Terraform-managed AWS SSM parameter."
  type        = string
  sensitive   = true
}

variable "r2_secret_access_key" {
  description = "Cloudflare R2 secret access key, matching the Terraform-managed AWS SSM parameter."
  type        = string
  sensitive   = true
}

variable "r2_bucket" {
  type    = string
  default = ""
}
