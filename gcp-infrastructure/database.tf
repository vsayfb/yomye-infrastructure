resource "random_string" "db_username_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "random_password" "database" {
  length  = 32
  special = true
}

locals {
  db_username = coalesce(var.db_user, "${local.resource_prefix}_${random_string.db_username_suffix.result}")
}

resource "google_sql_database_instance" "postgres" {
  name                = "${local.resource_prefix}-postgres"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = var.db_deletion_protection

  settings {
    # PostgreSQL 16 otherwise defaults to Enterprise Plus. The shared-core tier
    # used to mirror db.t4g.micro belongs to Cloud SQL Enterprise edition.
    edition           = "ENTERPRISE"
    tier              = var.db_tier
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.db_disk_size_gb
    disk_autoresize   = false

    location_preference {
      zone = var.zone
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "02:00"
      transaction_log_retention_days = var.db_transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.db_backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.id
      allocated_ip_range                            = google_compute_global_address.private_services.name
      enable_private_path_for_google_cloud_services = true
    }

    user_labels = local.labels
  }

  depends_on = [
    google_project_service.required["sqladmin.googleapis.com"],
    google_service_networking_connection.private_services,
  ]
}

resource "google_sql_database" "app" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app" {
  name     = local.db_username
  instance = google_sql_database_instance.postgres.name
  password = random_password.database.result
}

resource "google_secret_manager_secret" "database_credentials" {
  secret_id = "${local.resource_prefix}-database-credentials"
  labels    = local.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "database_credentials" {
  secret = google_secret_manager_secret.database_credentials.id
  secret_data = jsonencode({
    dbname   = google_sql_database.app.name
    engine   = "postgres"
    host     = google_sql_database_instance.postgres.private_ip_address
    password = random_password.database.result
    port     = 5432
    username = google_sql_user.app.name
  })
}
