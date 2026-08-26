output "backend_bucket" {
  value = google_storage_bucket.terraform_state.name
}

output "backend_hcl" {
  value = <<-EOT
    bucket = "${google_storage_bucket.terraform_state.name}"
    prefix = "production"
  EOT
}

