data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  remote_deploy_script_b64 = base64encode(file("${path.module}/scripts/remote-deploy.sh"))

  core_chat_otel_configure_script_b64 = base64encode(templatefile("${path.module}/scripts/configure-otel.sh.tpl", {
    service_name                = "core-chat"
    environment                 = var.environment
    grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
  }))

  worker_otel_configure_script_b64 = base64encode(templatefile("${path.module}/scripts/configure-otel.sh.tpl", {
    service_name                = "worker"
    environment                 = var.environment
    grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
  }))

  core_chat_startup = templatefile("${path.module}/scripts/bootstrap.sh.tpl", {
    service_name              = "core-chat"
    otel_collector_version    = var.otel_collector_version
    remote_deploy_script_b64  = local.remote_deploy_script_b64
    otel_configure_script_b64 = local.core_chat_otel_configure_script_b64
    install_ollama            = false
  })

  worker_startup = templatefile("${path.module}/scripts/bootstrap.sh.tpl", {
    service_name              = "worker"
    otel_collector_version    = var.otel_collector_version
    remote_deploy_script_b64  = local.remote_deploy_script_b64
    otel_configure_script_b64 = local.worker_otel_configure_script_b64
    install_ollama            = true
  })
}

resource "google_compute_instance_template" "core_chat" {
  name_prefix  = "${local.resource_prefix}-core-chat-"
  machine_type = var.core_chat_machine_type
  tags         = ["${local.resource_prefix}-core-chat"]
  labels       = merge(local.labels, { service = "core-chat" })

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.core_chat_boot_disk_size_gb
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    app-environment        = var.environment
  }
  metadata_startup_script = local.core_chat_startup

  service_account {
    email  = google_service_account.core_chat.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  can_ip_forward = false

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_compute_router_nat.main]
}

resource "google_compute_instance_template" "worker" {
  name_prefix  = "${local.resource_prefix}-worker-"
  machine_type = var.worker_machine_type
  tags         = ["${local.resource_prefix}-worker"]
  labels       = merge(local.labels, { service = "worker" })

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.worker_boot_disk_size_gb
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    app-environment        = var.environment
  }
  metadata_startup_script = local.worker_startup

  service_account {
    email  = google_service_account.worker.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  can_ip_forward = false

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_compute_router_nat.main]
}

resource "google_compute_instance_group_manager" "core_chat" {
  name               = "${local.resource_prefix}-core-chat"
  zone               = var.zone
  base_instance_name = "${local.resource_prefix}-core-chat"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.core_chat.id
  }

  named_port {
    name = "core"
    port = var.core_port
  }

  named_port {
    name = "chat"
    port = var.chat_port
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 1
    replacement_method             = "SUBSTITUTE"
  }
}

resource "google_compute_instance_group_manager" "worker" {
  name               = "${local.resource_prefix}-worker"
  zone               = var.zone
  base_instance_name = "${local.resource_prefix}-worker"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.worker.id
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 1
    replacement_method             = "SUBSTITUTE"
  }
}
