locals {
  # These IDs intentionally match the suffixes used below
  # /yevmiye/staging/ in AWS. Production runs in its own GCP project, so the
  # project provides the environment boundary and no path prefix is needed.
  managed_parameter_values = {
    "cloudinary-api-key"                = var.cloudinary_api_key
    "cloudinary-cloud-name"             = var.cloudinary_cloud_name
    "db-host"                           = google_sql_database_instance.postgres.private_ip_address
    "db-name"                           = google_sql_database.app.name
    "db-port"                           = "5432"
    "gemini-ai-model"                   = var.gemini_model
    "google-client-id"                  = var.google_client_id
    "grafana-cloud-opamp-endpoint"      = var.grafana_cloud_opamp_endpoint
    "groq-ai-endpoint"                  = var.groq_ai_endpoint
    "groq-ai-model"                     = var.groq_ai_model
    "mistral-ai-endpoint"               = var.mistral_ai_endpoint
    "mistral-ai-model"                  = var.mistral_ai_model
    "mongo-db-name"                     = var.mongo_db_name
    "nvidia-ai-endpoint"                = var.nvidia_ai_endpoint
    "nvidia-ai-model"                   = var.nvidia_ai_model
    "open_router-ai-endpoint"           = var.open_router_ai_endpoint
    "open_router-ai-model"              = var.open_router_ai_model
    "r2-account-id"                     = var.r2_account_id
    "r2-access-key-id"                  = var.r2_access_key_id
    "r2-bucket"                         = var.r2_bucket
    "r2-secret-access-key"              = var.r2_secret_access_key
    "rds-secret-arn"                    = google_secret_manager_secret.database_credentials.id
    "sqs-category-events-queue-url"     = google_pubsub_topic.category_events.id
    "sqs-notification-events-queue-url" = google_pubsub_topic.notification_events.id
    "ws-allowed-origins"                = var.ws_allowed_origins
  }

  managed_parameter_names = nonsensitive(toset(keys(local.managed_parameter_values)))

  all_parameter_names = setunion(
    local.managed_parameter_names,
    local.manual_parameter_names,
  )
}

resource "google_parameter_manager_parameter" "app" {
  for_each = local.all_parameter_names

  project      = var.project_id
  parameter_id = each.value
  format       = "UNFORMATTED"
  labels       = local.labels

  depends_on = [google_project_service.required["parametermanager.googleapis.com"]]
}

resource "google_parameter_manager_parameter_version" "managed" {
  for_each = local.managed_parameter_names

  parameter            = google_parameter_manager_parameter.app[each.value].id
  parameter_version_id = "terraform"
  parameter_data       = local.managed_parameter_values[each.value]
}
