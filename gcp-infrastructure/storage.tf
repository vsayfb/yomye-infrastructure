resource "google_storage_bucket" "app_deployments" {
  name                        = "${local.resource_prefix}-app-deployments-${data.google_project.current.number}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 2
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "notification_deployments" {
  name                        = "${local.resource_prefix}-notification-deployments-${data.google_project.current.number}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 2
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_artifact_registry_repository" "services" {
  location      = var.region
  repository_id = local.resource_prefix
  description   = "Yevmiye ${var.environment} service images"
  format        = "DOCKER"
  labels        = local.labels

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = 5
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "1209600s"
    }
  }

  depends_on = [google_project_service.required["artifactregistry.googleapis.com"]]
}

