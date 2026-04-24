# ===========================================================================
# Step 1: Global External Application Load Balancers (HTTP/HTTPS — Layer 7)
# Uses Google Front End (GFE) / Envoy proxies at every global edge PoP.
# Supports URL-based routing, Cloud CDN, Cloud Armor, and managed SSL certs.
# ===========================================================================

# 1a: Reserve global static anycast IP addresses (optional per LB).
# A global address is required when you need a stable IP for DNS or CDN.
resource "google_compute_global_address" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create && lb.reserve_ip_address }

  project = var.project_id
  name    = "${each.value.name}-ip"
}

# 1b: Create Google-managed SSL certificates for HTTPS frontends.
# Google auto-provisions and rotates the cert once the domain resolves to
# the forwarding rule IP. Provide ssl_domains when enable_https = true.
resource "google_compute_managed_ssl_certificate" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create && lb.enable_https && length(lb.ssl_domains) > 0 }

  project = var.project_id
  name    = "${each.value.name}-cert"

  managed {
    domains = each.value.ssl_domains
  }
}

# 1c: Global health checks — used by the backend service to determine
# which instances are healthy and eligible to receive traffic.
resource "google_compute_health_check" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create }

  project             = var.project_id
  name                = each.value.health_check.name
  check_interval_sec  = each.value.health_check.check_interval_sec
  timeout_sec         = each.value.health_check.timeout_sec
  healthy_threshold   = each.value.health_check.healthy_threshold
  unhealthy_threshold = each.value.health_check.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = each.value.health_check.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.health_check.protocol == "HTTPS" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.health_check.protocol == "TCP" ? [1] : []
    content {
      port = each.value.health_check.port
    }
  }
}

# 1d: Global backend services — define the instance groups or NEGs that
# serve traffic, with optional Cloud CDN and request logging.
resource "google_compute_backend_service" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  name                  = each.value.backend_service_name
  protocol              = each.value.protocol
  load_balancing_scheme = each.value.load_balancing_scheme
  session_affinity      = each.value.session_affinity
  timeout_sec           = each.value.timeout_sec
  enable_cdn            = each.value.enable_cdn

  health_checks = [google_compute_health_check.global_http[each.key].id]

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group                 = backend.value.group
      balancing_mode        = backend.value.balancing_mode
      capacity_scaler       = backend.value.capacity_scaler
      max_utilization       = backend.value.balancing_mode == "UTILIZATION" ? backend.value.max_utilization : null
      max_rate_per_instance = backend.value.balancing_mode == "RATE" ? backend.value.max_rate_per_instance : null
    }
  }

  dynamic "log_config" {
    for_each = each.value.enable_logging ? [1] : []
    content {
      enable      = true
      sample_rate = each.value.log_sample_rate
    }
  }
}

# 1e: URL maps define host- and path-based routing rules.
# The default_service catches all requests not matched by a routing rule.
resource "google_compute_url_map" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create }

  project         = var.project_id
  name            = each.value.url_map_name
  default_service = google_compute_backend_service.global_http[each.key].id
}

# 1f: Target HTTP proxies (created only when enable_https = false).
# The proxy connects the forwarding rule to the URL map.
resource "google_compute_target_http_proxy" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create && !lb.enable_https }

  project = var.project_id
  name    = "${each.value.name}-http-proxy"
  url_map = google_compute_url_map.global_http[each.key].id
}

# 1g: Target HTTPS proxies (created only when enable_https = true).
# Attaches the SSL certificate(s) and terminates TLS at Google's edge.
resource "google_compute_target_https_proxy" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create && lb.enable_https }

  project = var.project_id
  name    = "${each.value.name}-https-proxy"
  url_map = google_compute_url_map.global_http[each.key].id

  # Combine any newly created managed cert with pre-existing cert IDs
  ssl_certificates = concat(
    lookup({ for k, c in google_compute_managed_ssl_certificate.global_http : k => [c.id] }, each.key, []),
    each.value.ssl_cert_ids
  )
}

# Merge HTTP and HTTPS proxy IDs into a single map keyed by LB key.
# This avoids a Terraform plan error that occurs when both sides of a ternary
# are evaluated but only one proxy type exists per LB entry.
locals {
  global_http_proxy_ids = merge(
    { for k, p in google_compute_target_http_proxy.global_http : k => p.id },
    { for k, p in google_compute_target_https_proxy.global_http : k => p.id }
  )
}

# 1h: Global forwarding rules — the public entry point of each LB.
# Associates the anycast IP, port, and protocol with the target proxy.
resource "google_compute_global_forwarding_rule" "global_http" {
  for_each = { for lb in var.global_http_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  name                  = "${each.value.name}-forwarding-rule"
  target                = local.global_http_proxy_ids[each.key]
  load_balancing_scheme = each.value.load_balancing_scheme
  ip_address            = each.value.reserve_ip_address ? google_compute_global_address.global_http[each.key].address : null
  port_range            = each.value.enable_https ? "443" : "80"
}

# ===========================================================================
# Step 2: Regional Application Load Balancers (HTTP/HTTPS — Layer 7)
# Supports both EXTERNAL_MANAGED (public) and INTERNAL_MANAGED (private).
# Identical feature set to global LBs but scoped to a single region.
# ===========================================================================

# 2a: Reserve regional IP addresses for external or internal application LBs.
resource "google_compute_address" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create && lb.reserve_ip_address }

  project      = var.project_id
  name         = "${each.value.name}-ip"
  region       = trimspace(each.value.region) != "" ? each.value.region : var.region
  address_type = each.value.load_balancing_scheme == "INTERNAL_MANAGED" ? "INTERNAL" : "EXTERNAL"
  subnetwork   = each.value.load_balancing_scheme == "INTERNAL_MANAGED" && trimspace(each.value.subnetwork) != "" ? each.value.subnetwork : null
}

# 2b: Regional health checks scoped to the same region as the LB.
resource "google_compute_region_health_check" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create }

  project             = var.project_id
  region              = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                = each.value.health_check.name
  check_interval_sec  = each.value.health_check.check_interval_sec
  timeout_sec         = each.value.health_check.timeout_sec
  healthy_threshold   = each.value.health_check.healthy_threshold
  unhealthy_threshold = each.value.health_check.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = each.value.health_check.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.health_check.protocol == "HTTPS" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }
}

# 2c: Regional backend services. Use EXTERNAL_MANAGED for public traffic
# and INTERNAL_MANAGED for traffic that stays inside a VPC/region.
resource "google_compute_region_backend_service" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  region                = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                  = each.value.backend_service_name
  protocol              = each.value.protocol
  load_balancing_scheme = each.value.load_balancing_scheme
  session_affinity      = each.value.session_affinity
  timeout_sec           = each.value.timeout_sec

  health_checks = [google_compute_region_health_check.regional_http[each.key].id]

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      max_utilization = backend.value.balancing_mode == "UTILIZATION" ? backend.value.max_utilization : null
    }
  }

  dynamic "log_config" {
    for_each = each.value.enable_logging ? [1] : []
    content {
      enable      = true
      sample_rate = each.value.log_sample_rate
    }
  }
}

# 2d: Regional URL maps route requests to the default backend service.
resource "google_compute_region_url_map" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create }

  project         = var.project_id
  region          = trimspace(each.value.region) != "" ? each.value.region : var.region
  name            = each.value.url_map_name
  default_service = google_compute_region_backend_service.regional_http[each.key].id
}

# 2e: Regional target HTTP proxies (created only when enable_https = false).
resource "google_compute_region_target_http_proxy" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create && !lb.enable_https }

  project = var.project_id
  region  = trimspace(each.value.region) != "" ? each.value.region : var.region
  name    = "${each.value.name}-http-proxy"
  url_map = google_compute_region_url_map.regional_http[each.key].id
}

# 2f: Regional target HTTPS proxies (created only when enable_https = true).
# Provide ssl_cert_ids with pre-existing google_compute_region_ssl_certificate IDs.
resource "google_compute_region_target_https_proxy" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create && lb.enable_https }

  project          = var.project_id
  region           = trimspace(each.value.region) != "" ? each.value.region : var.region
  name             = "${each.value.name}-https-proxy"
  url_map          = google_compute_region_url_map.regional_http[each.key].id
  ssl_certificates = each.value.ssl_cert_ids
}

# Merge regional HTTP/HTTPS proxy IDs to avoid ternary evaluation errors.
locals {
  regional_http_proxy_ids = merge(
    { for k, p in google_compute_region_target_http_proxy.regional_http : k => p.id },
    { for k, p in google_compute_region_target_https_proxy.regional_http : k => p.id }
  )
}

# 2g: Regional forwarding rules — the entry point for each regional app LB.
# For INTERNAL_MANAGED, must specify network and subnetwork.
resource "google_compute_forwarding_rule" "regional_http" {
  for_each = { for lb in var.regional_http_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  region                = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                  = "${each.value.name}-forwarding-rule"
  target                = local.regional_http_proxy_ids[each.key]
  load_balancing_scheme = each.value.load_balancing_scheme
  ip_address            = each.value.reserve_ip_address ? google_compute_address.regional_http[each.key].address : null
  port_range            = each.value.enable_https ? "443" : "80"
  network               = trimspace(each.value.network) != "" ? each.value.network : null
  subnetwork            = trimspace(each.value.subnetwork) != "" ? each.value.subnetwork : null
}

# ===========================================================================
# Step 3: Regional External Passthrough Network Load Balancers (TCP/UDP — L4)
# Preserves the original client IP (no proxy). Ideal for game servers,
# financial trading, and UDP-based protocols.
# ===========================================================================

# 3a: Reserve external regional IP addresses for passthrough NLBs.
resource "google_compute_address" "network_lb" {
  for_each = { for lb in var.network_lbs : lb.key => lb if lb.create && lb.reserve_ip_address }

  project      = var.project_id
  name         = "${each.value.name}-ip"
  region       = trimspace(each.value.region) != "" ? each.value.region : var.region
  address_type = "EXTERNAL"
}

# 3b: Regional health checks for passthrough NLBs — TCP or HTTP depending
# on the application's ability to respond to health probe requests.
resource "google_compute_region_health_check" "network_lb" {
  for_each = { for lb in var.network_lbs : lb.key => lb if lb.create }

  project             = var.project_id
  region              = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                = each.value.health_check.name
  check_interval_sec  = each.value.health_check.check_interval_sec
  timeout_sec         = each.value.health_check.timeout_sec
  healthy_threshold   = each.value.health_check.healthy_threshold
  unhealthy_threshold = each.value.health_check.unhealthy_threshold

  dynamic "tcp_health_check" {
    for_each = each.value.health_check.protocol == "TCP" ? [1] : []
    content {
      port = each.value.health_check.port
    }
  }

  dynamic "http_health_check" {
    for_each = each.value.health_check.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }
}

# 3c: Regional backend services for passthrough NLBs.
# EXTERNAL scheme passes TCP/UDP through without terminating the connection.
resource "google_compute_region_backend_service" "network_lb" {
  for_each = { for lb in var.network_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  region                = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                  = "${each.value.name}-backend"
  protocol              = each.value.protocol
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_region_health_check.network_lb[each.key].id]

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
    }
  }
}

# 3d: Regional forwarding rules for passthrough NLBs.
# Uses backend_service (not target proxy) — characteristic of L4 passthrough.
resource "google_compute_forwarding_rule" "network_lb" {
  for_each = { for lb in var.network_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  region                = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                  = "${each.value.name}-forwarding-rule"
  backend_service       = google_compute_region_backend_service.network_lb[each.key].id
  load_balancing_scheme = "EXTERNAL"
  ip_address            = each.value.reserve_ip_address ? google_compute_address.network_lb[each.key].address : null
  ip_protocol           = each.value.protocol
  ports                 = each.value.all_ports ? null : (length(each.value.ports) > 0 ? each.value.ports : null)
  all_ports             = each.value.all_ports
}

# ===========================================================================
# Step 4: Regional Internal Passthrough Network Load Balancers (TCP/UDP — L4)
# All traffic stays within the VPC — no external IP is assigned.
# Supports global_access to allow cross-region traffic from the same VPC.
# ===========================================================================

# 4a: Regional health checks for internal passthrough NLBs.
resource "google_compute_region_health_check" "internal_lb" {
  for_each = { for lb in var.internal_lbs : lb.key => lb if lb.create }

  project             = var.project_id
  region              = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                = each.value.health_check.name
  check_interval_sec  = each.value.health_check.check_interval_sec
  timeout_sec         = each.value.health_check.timeout_sec
  healthy_threshold   = each.value.health_check.healthy_threshold
  unhealthy_threshold = each.value.health_check.unhealthy_threshold

  dynamic "tcp_health_check" {
    for_each = each.value.health_check.protocol == "TCP" ? [1] : []
    content {
      port = each.value.health_check.port
    }
  }

  dynamic "http_health_check" {
    for_each = each.value.health_check.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.health_check.port
      request_path = each.value.health_check.request_path
    }
  }
}

# 4b: Regional backend services for internal passthrough NLBs.
# INTERNAL scheme keeps all traffic within the VPC.
resource "google_compute_region_backend_service" "internal_lb" {
  for_each = { for lb in var.internal_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  region                = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                  = "${each.value.name}-backend"
  protocol              = each.value.protocol
  load_balancing_scheme = "INTERNAL"

  health_checks = [google_compute_region_health_check.internal_lb[each.key].id]

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
    }
  }
}

# 4c: Regional forwarding rules for internal passthrough NLBs.
# Must specify network and subnetwork. global_access allows traffic from
# other regions within the same VPC (useful for hub-and-spoke topologies).
resource "google_compute_forwarding_rule" "internal_lb" {
  for_each = { for lb in var.internal_lbs : lb.key => lb if lb.create }

  project               = var.project_id
  region                = trimspace(each.value.region) != "" ? each.value.region : var.region
  name                  = "${each.value.name}-forwarding-rule"
  backend_service       = google_compute_region_backend_service.internal_lb[each.key].id
  load_balancing_scheme = "INTERNAL"
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  ip_protocol           = each.value.protocol
  ports                 = each.value.all_ports ? null : (length(each.value.ports) > 0 ? each.value.ports : null)
  all_ports             = each.value.all_ports
  allow_global_access   = each.value.global_access
}
