resource "google_service_account" "core_chat" {
  account_id   = "${var.name_prefix}-core-chat"
  display_name = "Yevmiye ${var.environment} Core and Chat"
}

resource "google_service_account" "worker" {
  account_id   = "${var.name_prefix}-worker"
  display_name = "Yevmiye ${var.environment} categorization worker"
}

resource "google_service_account" "notification" {
  account_id   = "${var.name_prefix}-notify"
  display_name = "Yevmiye ${var.environment} notification service"
}

resource "google_service_account" "notification_push" {
  account_id   = "${var.name_prefix}-push"
  display_name = "Pub/Sub identity for ${var.environment} notification delivery"
}

resource "google_service_account" "github_deploy" {
  account_id   = "${var.name_prefix}-deploy"
  display_name = "GitHub Actions ${var.environment} deployer"
}

locals {
  workload_service_accounts = {
    core_chat    = google_service_account.core_chat.email
    worker       = google_service_account.worker.email
    notification = google_service_account.notification.email
  }

  common_workload_roles = toset(["roles/logging.logWriter", "roles/monitoring.metricWriter"])

  common_workload_role_bindings = merge([
    for workload, email in local.workload_service_accounts : {
      for role in local.common_workload_roles : "${workload}:${role}" => {
        email = email
        role  = role
      }
    }
  ]...)
}

resource "google_project_iam_member" "workload_telemetry" {
  for_each = local.common_workload_role_bindings

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${each.value.email}"
}

resource "google_project_iam_member" "parameter_accessor" {
  for_each = local.workload_service_accounts

  project = var.project_id
  role    = "roles/parametermanager.parameterAccessor"
  member  = "serviceAccount:${each.value}"
}

resource "google_secret_manager_secret_iam_member" "database_credentials" {
  for_each = local.workload_service_accounts

  project   = var.project_id
  secret_id = google_secret_manager_secret.database_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value}"
}

resource "google_storage_bucket_iam_member" "core_chat_artifacts" {
  bucket = google_storage_bucket.app_deployments.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.core_chat.email}"
}

resource "google_storage_bucket_iam_member" "worker_artifacts" {
  bucket = google_storage_bucket.app_deployments.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.worker.email}"
}
