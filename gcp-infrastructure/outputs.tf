output "load_balancer_ip" {
  description = "Public IP of the HTTP application load balancer."
  value       = google_compute_global_address.load_balancer.address
}

output "nat_ip" {
  description = "Stable public source IP used by private workloads for outbound traffic."
  value       = google_compute_address.nat.address
}

output "project_id" {
  description = "Google Cloud project containing the production environment."
  value       = var.project_id
}

output "region" {
  value = var.region
}

output "application_url" {
  value = "http://${google_compute_global_address.load_balancer.address}"
}

output "core_chat_instance_group" {
  value = google_compute_instance_group_manager.core_chat.name
}

output "worker_instance_group" {
  value = google_compute_instance_group_manager.worker.name
}

output "compute_zone" {
  value = var.zone
}

output "cloud_sql_instance_name" {
  value = google_sql_database_instance.postgres.name
}

output "cloud_sql_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "app_deployments_bucket" {
  value = google_storage_bucket.app_deployments.name
}

output "notification_deployments_bucket" {
  value = google_storage_bucket.notification_deployments.name
}

output "artifact_registry_repository" {
  value = "${google_artifact_registry_repository.services.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.services.repository_id}"
}

output "notification_service_uri" {
  value = google_cloud_run_v2_service.notification.uri
}

output "notification_service_name" {
  value = google_cloud_run_v2_service.notification.name
}

output "database_credentials_secret" {
  value = google_secret_manager_secret.database_credentials.secret_id
}

output "parameter_names" {
  description = "Parameter Manager IDs; these match the AWS SSM suffix constants."
  value       = sort(tolist(local.all_parameter_names))
}

output "github_workload_identity_provider" {
  description = "Use as google-github-actions/auth workload_identity_provider."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_deploy_service_account" {
  description = "Use as google-github-actions/auth service_account."
  value       = google_service_account.github_deploy.email
}

output "pubsub_topics" {
  value = {
    category_events     = google_pubsub_topic.category_events.id
    chat_events         = google_pubsub_topic.chat_events.id
    notification_events = google_pubsub_topic.notification_events.id
  }
}
