project_id = "my-project"
region     = "us-central1"

tags = {
  env     = "dev"
  team    = "platform"
  owner   = "infra-team"
  project = "my-project"
}

# ── Global External Application LB (HTTP/HTTPS L7) ──────────────────────────
# Use for public-facing web apps that need global anycast IP and CDN integration.
# Set create = true once your backend MIG or NEG self-links are available.
global_http_lbs = [
  {
    key                   = "web-global-lb"
    create                = true
    name                  = "web-global-lb"
    enable_https          = true
    ssl_domains           = ["example.com", "www.example.com"]
    ssl_cert_ids          = []
    reserve_ip_address    = true
    load_balancing_scheme = "EXTERNAL_MANAGED"
    backend_service_name  = "web-global-backend"
    protocol              = "HTTP"
    session_affinity      = "NONE"
    timeout_sec           = 30
    enable_cdn            = true
    enable_logging        = true
    log_sample_rate       = 1.0
    backends = [
      {
        # Replace with your MIG or NEG self-link
        group                 = "projects/my-project/regions/us-central1/instanceGroups/web-mig"
        balancing_mode        = "UTILIZATION"
        capacity_scaler       = 1.0
        max_utilization       = 0.8
        max_rate_per_instance = 0
      }
    ]
    health_check = {
      name                = "web-global-hc"
      protocol            = "HTTP"
      port                = 80
      request_path        = "/health"
      check_interval_sec  = 10
      timeout_sec         = 5
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
    url_map_name = "web-global-url-map"
  }
]

# ── Regional External / Internal Application LB (HTTP/HTTPS L7) ─────────────
# Use EXTERNAL_MANAGED for regional external traffic; INTERNAL_MANAGED for
# private service mesh or GKE internal ingress within a VPC.
regional_http_lbs = [
  {
    key                   = "api-regional-lb"
    create                = false
    name                  = "api-regional-lb"
    region                = "us-central1"
    load_balancing_scheme = "INTERNAL_MANAGED"
    enable_https          = false
    ssl_cert_ids          = []
    # Required for INTERNAL_MANAGED:
    network              = "projects/my-project/global/networks/default"
    subnetwork           = "projects/my-project/regions/us-central1/subnetworks/default"
    reserve_ip_address   = false
    backend_service_name = "api-regional-backend"
    protocol             = "HTTP"
    session_affinity     = "NONE"
    timeout_sec          = 30
    enable_logging       = true
    log_sample_rate      = 0.5
    backends = [
      {
        group           = "projects/my-project/regions/us-central1/instanceGroups/api-mig"
        balancing_mode  = "UTILIZATION"
        capacity_scaler = 1.0
        max_utilization = 0.8
      }
    ]
    health_check = {
      name                = "api-regional-hc"
      protocol            = "HTTP"
      port                = 8080
      request_path        = "/healthz"
      check_interval_sec  = 10
      timeout_sec         = 5
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
    url_map_name = "api-regional-url-map"
  }
]

# ── Regional External Passthrough NLB (TCP/UDP L4) ───────────────────────────
# Use for protocols that require direct IP passthrough (game servers, custom TCP,
# high-throughput UDP, connection-heavy workloads).
network_lbs = [
  {
    key                = "game-udp-nlb"
    create             = false
    name               = "game-udp-nlb"
    region             = "us-central1"
    protocol           = "UDP"
    all_ports          = false
    ports              = ["7777", "7778"]
    reserve_ip_address = true
    backends = [
      {
        group           = "projects/my-project/regions/us-central1/instanceGroups/game-mig"
        balancing_mode  = "CONNECTION"
        capacity_scaler = 1.0
      }
    ]
    health_check = {
      name                = "game-udp-hc"
      protocol            = "HTTP"
      port                = 8080
      request_path        = "/health"
      check_interval_sec  = 10
      timeout_sec         = 5
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
  }
]

# ── Regional Internal Passthrough NLB (TCP/UDP L4) ───────────────────────────
# Use for private workloads inside a VPC: database proxies, internal caches,
# service-to-service TCP forwarding without HTTP inspection.
internal_lbs = [
  {
    key           = "db-proxy-ilb"
    create        = false
    name          = "db-proxy-ilb"
    region        = "us-central1"
    protocol      = "TCP"
    all_ports     = false
    ports         = ["5432"]
    network       = "projects/my-project/global/networks/default"
    subnetwork    = "projects/my-project/regions/us-central1/subnetworks/default"
    global_access = false
    backends = [
      {
        group           = "projects/my-project/regions/us-central1/instanceGroups/db-proxy-mig"
        balancing_mode  = "CONNECTION"
        capacity_scaler = 1.0
      }
    ]
    health_check = {
      name                = "db-proxy-hc"
      protocol            = "TCP"
      port                = 5432
      request_path        = "/"
      check_interval_sec  = 10
      timeout_sec         = 5
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
  }
]
