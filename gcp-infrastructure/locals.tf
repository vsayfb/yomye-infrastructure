locals {
  # The GCP project is the environment boundary, so resource names mirror the
  # current AWS names and do not repeat the environment name.
  resource_prefix = var.name_prefix

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.name_prefix
  })

  required_apis = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "parametermanager.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sts.googleapis.com",
  ])

  manual_parameter_names = toset([
    "cloudinary-api-secret",
    "firebase-credentials",
    "gemini-api-key",
    "groq-api-key",
    "jwt-secret",
    "mistral-api-key",
    "mongo-db-uri",
    "nvidia-api-key",
    "open-router-api-key",
    "otlp-auth-token",
    "otlp-write-key",
  ])
}
