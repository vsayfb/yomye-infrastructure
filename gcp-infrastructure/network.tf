resource "google_compute_network" "main" {
  name                    = "${local.resource_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.required["compute.googleapis.com"]]
}

resource "google_compute_subnetwork" "private" {
  name                     = "${local.resource_prefix}-private"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.network_cidr
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_vpc_flow_logs ? [1] : []

    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

resource "google_compute_router" "main" {
  name    = "${local.resource_prefix}-router"
  region  = var.region
  network = google_compute_network.main.id
}

# Managed Cloud NAT is the GCP-native equivalent of the AWS t3.micro NAT
# instance. It avoids maintaining an extra VM and is cheaper for this footprint
# at low-to-moderate NAT traffic volumes.
resource "google_compute_router_nat" "main" {
  name                               = "${local.resource_prefix}-nat"
  region                             = var.region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  dynamic "log_config" {
    for_each = var.enable_nat_logging ? [1] : []

    content {
      enable = true
      filter = "ERRORS_ONLY"
    }
  }
}

resource "google_compute_firewall" "load_balancer_to_apps" {
  name      = "${local.resource_prefix}-lb-to-apps"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]
  target_tags = ["${local.resource_prefix}-core-chat"]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.core_port), tostring(var.chat_port)]
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name      = "${local.resource_prefix}-iap-ssh"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]
  target_tags = [
    "${local.resource_prefix}-core-chat",
    "${local.resource_prefix}-worker",
  ]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_global_address" "private_services" {
  name          = "${local.resource_prefix}-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id

  depends_on = [google_project_service.required["servicenetworking.googleapis.com"]]
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}
