resource "google_compute_health_check" "core" {
  name               = "${local.resource_prefix}-core"
  timeout_sec        = 5
  check_interval_sec = 30

  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.core_port
    request_path = "/ready"
  }
}

resource "google_compute_health_check" "chat" {
  name               = "${local.resource_prefix}-chat"
  timeout_sec        = 5
  check_interval_sec = 30

  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.chat_port
    request_path = "/ready"
  }
}

resource "google_compute_backend_service" "core" {
  name                  = "${local.resource_prefix}-core"
  protocol              = "HTTP"
  port_name             = "core"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 3600
  health_checks         = [google_compute_health_check.core.id]

  backend {
    group           = google_compute_instance_group_manager.core_chat.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  dynamic "log_config" {
    for_each = var.enable_load_balancer_logging ? [1] : []

    content {
      enable      = true
      sample_rate = 1.0
    }
  }
}

resource "google_compute_backend_service" "chat" {
  name                  = "${local.resource_prefix}-chat"
  protocol              = "HTTP"
  port_name             = "chat"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 3600
  health_checks         = [google_compute_health_check.chat.id]

  backend {
    group           = google_compute_instance_group_manager.core_chat.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  dynamic "log_config" {
    for_each = var.enable_load_balancer_logging ? [1] : []

    content {
      enable      = true
      sample_rate = 1.0
    }
  }
}

resource "google_compute_url_map" "apps" {
  name            = "${local.resource_prefix}-apps"
  default_service = google_compute_backend_service.core.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "services"
  }

  path_matcher {
    name            = "services"
    default_service = google_compute_backend_service.core.id

    route_rules {
      priority = 10
      service  = google_compute_backend_service.core.id

      match_rules {
        full_path_match = "/core/health"
      }

      route_action {
        url_rewrite {
          path_prefix_rewrite = "/health"
        }
      }
    }

    route_rules {
      priority = 20
      service  = google_compute_backend_service.core.id

      match_rules {
        full_path_match = "/core/ready"
      }

      route_action {
        url_rewrite {
          path_prefix_rewrite = "/ready"
        }
      }
    }

    route_rules {
      priority = 30
      service  = google_compute_backend_service.chat.id

      match_rules {
        full_path_match = "/chat"
      }

      route_action {
        url_rewrite {
          path_prefix_rewrite = "/"
        }
      }
    }

    route_rules {
      priority = 40
      service  = google_compute_backend_service.chat.id

      match_rules {
        prefix_match = "/chat/"
      }

      route_action {
        url_rewrite {
          path_prefix_rewrite = "/"
        }
      }
    }

    path_rule {
      paths   = ["/core", "/core/*"]
      service = google_compute_backend_service.core.id
    }
  }
}

resource "google_compute_global_address" "load_balancer" {
  name = "${local.resource_prefix}-lb"
}

# The current AWS ALB exposes a single HTTP listener. Keep the GCP baseline
# equivalent; TLS can be layered on later without changing application backends.
resource "google_compute_target_http_proxy" "apps" {
  name    = "${local.resource_prefix}-http"
  url_map = google_compute_url_map.apps.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${local.resource_prefix}-http"
  ip_address            = google_compute_global_address.load_balancer.id
  ip_protocol           = "TCP"
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.apps.id
}
