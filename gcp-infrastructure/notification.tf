resource "google_cloud_run_v2_service" "notification" {
  name                = "${local.resource_prefix}-notification"
  location            = var.region
  deletion_protection = var.notification_deletion_protection
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  labels              = local.labels

  template {
    service_account = google_service_account.notification.email
    timeout         = var.notification_timeout

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = var.notification_bootstrap_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      env {
        name  = "APP_ENV"
        value = var.environment
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }

      env {
        name  = "GCP_PARAMETER_LOCATION"
        value = "global"
      }

      env {
        name  = "GCP_RDS_SECRET_PARAMETER"
        value = "rds-secret-arn"
      }

      env {
        name  = "GCP_FIREBASE_CREDENTIALS_PARAMETER"
        value = "firebase-credentials"
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = google_compute_network.main.name
        subnetwork = google_compute_subnetwork.private.name
      }
    }
  }

  depends_on = [
    google_project_service.required["run.googleapis.com"],
    google_secret_manager_secret_iam_member.database_credentials,
    google_project_iam_member.parameter_accessor,
  ]

  lifecycle {
    # Terraform provisions the service and bootstrap image. GitHub Actions owns
    # the real application image after the first deployment.
    ignore_changes = [template[0].containers[0].image]
  }
}

resource "google_cloud_run_v2_service_iam_member" "notification_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.notification.location
  name     = google_cloud_run_v2_service.notification.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.notification_push.email}"
}

resource "google_project_service_identity" "pubsub" {
  provider = google-beta
  project  = var.project_id
  service  = "pubsub.googleapis.com"

  depends_on = [google_project_service.required["pubsub.googleapis.com"]]
}

resource "google_project_iam_member" "pubsub_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

resource "google_pubsub_subscription" "notification" {
  name  = "${local.resource_prefix}-notification"
  topic = google_pubsub_topic.notification_events.id

  ack_deadline_seconds       = 90
  message_retention_duration = "345600s"
  labels                     = local.labels

  dynamic "push_config" {
    for_each = var.notification_delivery_enabled ? [1] : []

    content {
      push_endpoint = google_cloud_run_v2_service.notification.uri

      oidc_token {
        service_account_email = google_service_account.notification_push.email
        audience              = google_cloud_run_v2_service.notification.uri
      }

      attributes = {
        x-goog-version = "v1"
      }
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  expiration_policy {
    ttl = ""
  }

  depends_on = [
    google_cloud_run_v2_service_iam_member.notification_invoker,
    google_project_iam_member.pubsub_token_creator,
  ]
}
