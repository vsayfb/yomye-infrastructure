variable "project_id" {
  description = "Existing Google Cloud project in which production will be created."
  type        = string
}

variable "region" {
  description = "Primary Google Cloud region. europe-west3 is Frankfurt."
  type        = string
  default     = "europe-west3"
}

variable "zones" {
  description = "Zones used by the regional managed instance groups."
  type        = list(string)
  default     = ["europe-west3-a", "europe-west3-b"]

  validation {
    condition     = length(var.zones) >= 2
    error_message = "Production requires at least two zones."
  }
}

variable "name_prefix" {
  type    = string
  default = "yevmiye"
}

variable "environment" {
  type    = string
  default = "production"

  validation {
    condition     = var.environment == "production"
    error_message = "This root is intentionally production-only."
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

variable "core_port" {
  type    = number
  default = 8080
}

variable "chat_port" {
  type    = number
  default = 8081
}

variable "core_chat_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "worker_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "worker_boot_disk_size_gb" {
  description = "Worker disk also holds the local Ollama model."
  type        = number
  default     = 30
}

variable "db_name" {
  type    = string
  default = "yevmiye"
}

variable "db_user" {
  type    = string
  default = "yevmiye_app"
}

variable "db_tier" {
  type    = string
  default = "db-custom-1-3840"
}

variable "db_disk_size_gb" {
  type    = number
  default = 20
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "db_backup_retention_count" {
  type    = number
  default = 7
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
  description = "Maximum request duration for a Pub/Sub delivery."
  type        = string
  default     = "60s"
}

variable "notification_deletion_protection" {
  description = "Prevent accidental deletion of the production notification service."
  type        = bool
  default     = true
}

variable "managed_certificate_domains" {
  description = "Public DNS names for the HTTPS load balancer. Point them at the load_balancer_ip output."
  type        = list(string)

  validation {
    condition     = length(var.managed_certificate_domains) > 0
    error_message = "At least one production domain is required."
  }
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
