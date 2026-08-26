provider "google" {
  project = var.project_id
}

data "google_project" "current" {
  project_id = var.project_id
}

