variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Networking inputs, from the network module
variable "vpc_id" {
  type = string
}

variable "alb_subnet_ids" {
  description = "Public subnet IDs (2 AZs) for the ALB."
  type        = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "compute_subnet_id" {
  description = "The private subnet (AZ index 0) where applications actually launch."
  type        = string
}

variable "private_services_sg_id" {
  type = string
}

# Instances
variable "app_port_range" {
  description = "Core's port (from) and Chat's port (to) - the range the ALB is allowed to reach on private_services_sg, and what compute/'s target groups listen on."
  type = object({
    from = number
    to   = number
  })
  default = {
    from = 8080
    to   = 8081
  }
}

variable "core_chat_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.small"
}

variable "core_port" {
  description = "Port Core's HTTP server listens on."
  type        = number
  default     = 8080
}

variable "chat_port" {
  description = "Port Chat's WebSocket server listens on."
  type        = number
  default     = 8081
}

# Data inputs, from the data module
variable "rds_secret_read_policy_arn" {
  type = string
}

variable "core_sqs_produce_policy_arn" {
  type = string
}

variable "worker_sqs_access_policy_arn" {
  type = string
}

# Observability inputs
variable "observability_read_policy_arn" {
  type = string
}


# ALB
variable "core_path_pattern" {
  description = "ALB listener rule path pattern routed to Core's target group."
  type        = list(string)
  default     = ["/core/*"]
}

variable "chat_path_pattern" {
  description = "ALB listener rule path pattern routed to Chat's target group."
  type        = list(string)
  default     = ["/chat/*"]
}

variable "alb_idle_timeout" {
  description = "Must be raised well above the 60s default or idle WebSocket connections get dropped."
  type        = number
  default     = 3600
}

variable "health_check_path" {
  description = "Shared health-check path for both target groups."
  type        = string
  default     = "/ready"
}

# OTel Collector / OpAMP Supervisor

variable "opamp_endpoint_parameter_name" {
  description = "Grafana Cloud Fleet Management OpAMP endpoint."
  type        = string
}

variable "opamp_auth_token_parameter_name" {
  description = "Name of the SSM SecureString parameter holding the OpAMP Authorization header value."
  type        = string
}

variable "otlp_write_key_parameter_name" {
  type = string
}

variable "grafana_cloud_otlp_endpoint" {
  description = "Grafana Cloud OTLP ingestion endpoint."
  type        = string
}

variable "otel_collector_version" {
  type    = string
  default = "0.156.0"
}

variable "opamp_supervisor_version" {
  type    = string
  default = "0.23.0"
}

variable "app_deployments_read_policy_arn" {
  type = string
}

# Runtime config, from data/

variable "app_config_read_policy_arn" {
  type = string
}

variable "jwt_secret_read_policy_arn" {
  description = "Attached to core_chat only - Worker doesn't do auth."
  type        = string
}

variable "mongodb_uri_secret_read_policy_arn" {
  description = "Attached to chat only."
  type        = string
}

variable "groq_ai_secret_read_policy_arn" {
  description = "Attached to worker only."
  type        = string
}

variable "open_router_ai_secret_read_policy_arn" {
  description = "Attached to worker only."
  type        = string
}

variable "gemini_ai_secret_read_policy_arn" {
  description = "Attached to worker only."
  type        = string
}

variable "nvidia_ai_secret_read_policy_arn" {
  description = "Attached to worker only."
  type        = string
}

variable "cloudinary_api_secret_read_policy_arn" {
  type = string
}
