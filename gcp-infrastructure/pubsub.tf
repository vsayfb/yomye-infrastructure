resource "google_pubsub_topic" "category_events" {
  name                       = "${local.resource_prefix}-category-events"
  message_retention_duration = "345600s"
  labels                     = local.labels

  depends_on = [google_project_service.required["pubsub.googleapis.com"]]
}

resource "google_pubsub_topic" "chat_events" {
  name                       = "${local.resource_prefix}-chat-events"
  message_retention_duration = "345600s"
  labels                     = local.labels

  depends_on = [google_project_service.required["pubsub.googleapis.com"]]
}

resource "google_pubsub_topic" "notification_events" {
  name                       = "${local.resource_prefix}-notification-events"
  message_retention_duration = "345600s"
  labels                     = local.labels

  depends_on = [google_project_service.required["pubsub.googleapis.com"]]
}

resource "google_pubsub_subscription" "category_worker" {
  name  = "${local.resource_prefix}-category-worker"
  topic = google_pubsub_topic.category_events.id

  ack_deadline_seconds       = 90
  message_retention_duration = "345600s"
  retain_acked_messages      = false
  enable_message_ordering    = false
  labels                     = local.labels

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  expiration_policy {
    ttl = ""
  }
}

resource "google_pubsub_topic_iam_member" "core_category_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.category_events.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.core_chat.email}"
}

resource "google_pubsub_topic_iam_member" "core_notification_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.notification_events.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.core_chat.email}"
}

resource "google_pubsub_topic_iam_member" "worker_notification_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.notification_events.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_pubsub_subscription_iam_member" "worker_category_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.category_worker.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.worker.email}"
}

