# ---------------------------------------------------------------------------
# Default project for all load balancer resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used for all load balancer resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for all regional load balancer resources.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region for regional load balancer resources. Can be overridden per entry."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels applied to module outputs.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Global External Application Load Balancers (HTTP/HTTPS — Layer 7)
# Each entry creates: global IP (optional), managed SSL cert (optional),
# global health check, global backend service, URL map, target proxy,
# and global forwarding rule.
# ---------------------------------------------------------------------------
variable "global_http_lbs" {
  description = "List of global external application load balancers (HTTP/HTTPS Layer 7). Each entry creates the full resource stack."
  type = list(object({
    key    = string
    create = optional(bool, true)
    name   = string

    # Set true for HTTPS — creates a target HTTPS proxy and uses port 443
    enable_https = optional(bool, false)
    # Domains for Google-managed SSL certificate (used when enable_https = true and ssl_domains is set)
    ssl_domains = optional(list(string), [])
    # Self-links to pre-existing SSL certificates (alternative to managed certs)
    ssl_cert_ids = optional(list(string), [])

    # Set true to reserve a global static anycast IP address
    reserve_ip_address    = optional(bool, false)
    load_balancing_scheme = optional(string, "EXTERNAL_MANAGED") # EXTERNAL_MANAGED (Envoy) or EXTERNAL (classic)

    # Backend service configuration
    backend_service_name = string
    protocol             = optional(string, "HTTP") # HTTP, HTTPS, HTTP2
    session_affinity     = optional(string, "NONE") # NONE, CLIENT_IP, GENERATED_COOKIE
    timeout_sec          = optional(number, 30)
    enable_cdn           = optional(bool, false)

    # List of backend groups (instance groups or NEGs)
    backends = list(object({
      group                 = string                          # self-link of instance group or NEG
      balancing_mode        = optional(string, "UTILIZATION") # UTILIZATION, RATE, CONNECTION
      capacity_scaler       = optional(number, 1.0)
      max_utilization       = optional(number, 0.8) # used with UTILIZATION mode
      max_rate_per_instance = optional(number, 0)   # used with RATE mode; 0 = not set
    }))

    # Health check configuration
    health_check = object({
      name                = string
      protocol            = optional(string, "HTTP") # HTTP, HTTPS, TCP
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })

    url_map_name    = string
    enable_logging  = optional(bool, false)
    log_sample_rate = optional(number, 1.0) # 0.0–1.0; fraction of requests to log
  }))
  default = []

  validation {
    condition     = length(distinct([for lb in var.global_http_lbs : lb.key])) == length(var.global_http_lbs)
    error_message = "global_http_lbs[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for lb in var.global_http_lbs : contains(["EXTERNAL_MANAGED", "EXTERNAL"], lb.load_balancing_scheme)
    ])
    error_message = "global_http_lbs[*].load_balancing_scheme must be EXTERNAL_MANAGED or EXTERNAL."
  }
}

# ---------------------------------------------------------------------------
# Regional Application Load Balancers (HTTP/HTTPS — Layer 7)
# Supports both EXTERNAL_MANAGED (public) and INTERNAL_MANAGED (private VPC).
# Each entry creates the full regional resource stack.
# ---------------------------------------------------------------------------
variable "regional_http_lbs" {
  description = "List of regional application load balancers (external or internal HTTP/HTTPS Layer 7). Each entry creates the full regional resource stack."
  type = list(object({
    key    = string
    create = optional(bool, true)
    name   = string
    region = optional(string, "") # overrides var.region when set

    # EXTERNAL_MANAGED = public regional LB; INTERNAL_MANAGED = internal (VPC-only)
    load_balancing_scheme = optional(string, "EXTERNAL_MANAGED")

    # Set true for HTTPS — requires ssl_cert_ids (regional managed certs or self-managed)
    enable_https = optional(bool, false)
    # Self-links to google_compute_region_ssl_certificate resources
    ssl_cert_ids = optional(list(string), [])

    # Required for INTERNAL_MANAGED: the VPC network and subnetwork
    network    = optional(string, "")
    subnetwork = optional(string, "")

    # Set true to reserve a regional static IP address
    reserve_ip_address = optional(bool, false)

    # Backend service configuration
    backend_service_name = string
    protocol             = optional(string, "HTTP") # HTTP, HTTPS, HTTP2
    session_affinity     = optional(string, "NONE")
    timeout_sec          = optional(number, 30)

    backends = list(object({
      group           = string
      balancing_mode  = optional(string, "UTILIZATION")
      capacity_scaler = optional(number, 1.0)
      max_utilization = optional(number, 0.8)
    }))

    health_check = object({
      name                = string
      protocol            = optional(string, "HTTP")
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })

    url_map_name    = string
    enable_logging  = optional(bool, false)
    log_sample_rate = optional(number, 1.0)
  }))
  default = []

  validation {
    condition     = length(distinct([for lb in var.regional_http_lbs : lb.key])) == length(var.regional_http_lbs)
    error_message = "regional_http_lbs[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for lb in var.regional_http_lbs : contains(["EXTERNAL_MANAGED", "INTERNAL_MANAGED"], lb.load_balancing_scheme)
    ])
    error_message = "regional_http_lbs[*].load_balancing_scheme must be EXTERNAL_MANAGED or INTERNAL_MANAGED."
  }
}

# ---------------------------------------------------------------------------
# Regional External Passthrough Network Load Balancers (TCP/UDP — Layer 4)
# Preserves the original client source IP. No TLS termination.
# Ideal for game servers, VoIP, financial data feeds, and UDP workloads.
# ---------------------------------------------------------------------------
variable "network_lbs" {
  description = "List of regional external passthrough network load balancers (TCP/UDP Layer 4). Client IP is preserved."
  type = list(object({
    key    = string
    create = optional(bool, true)
    name   = string
    region = optional(string, "")

    protocol  = optional(string, "TCP")    # TCP or UDP
    all_ports = optional(bool, false)      # true = forward all ports to backends
    ports     = optional(list(string), []) # specific ports, e.g. ["80", "443"]

    # Set true to reserve an external regional static IP
    reserve_ip_address = optional(bool, false)

    backends = list(object({
      group           = string
      balancing_mode  = optional(string, "CONNECTION") # CONNECTION, UTILIZATION
      capacity_scaler = optional(number, 1.0)
    }))

    health_check = object({
      name                = string
      protocol            = optional(string, "TCP") # TCP or HTTP
      port                = optional(number, 80)
      request_path        = optional(string, "/") # only used when protocol = HTTP
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })
  }))
  default = []

  validation {
    condition     = length(distinct([for lb in var.network_lbs : lb.key])) == length(var.network_lbs)
    error_message = "network_lbs[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for lb in var.network_lbs : contains(["TCP", "UDP"], lb.protocol)
    ])
    error_message = "network_lbs[*].protocol must be TCP or UDP."
  }
}

# ---------------------------------------------------------------------------
# Regional Internal Passthrough Network Load Balancers (TCP/UDP — Layer 4)
# Traffic stays within the VPC. No external IP. Optionally allow global
# access to serve traffic from other regions in the same VPC.
# ---------------------------------------------------------------------------
variable "internal_lbs" {
  description = "List of regional internal passthrough network load balancers (TCP/UDP Layer 4). Traffic stays within the VPC."
  type = list(object({
    key    = string
    create = optional(bool, true)
    name   = string
    region = optional(string, "")

    protocol  = optional(string, "TCP") # TCP or UDP
    all_ports = optional(bool, false)
    ports     = optional(list(string), [])

    # Required: VPC network and subnetwork for the internal forwarding rule
    network    = string
    subnetwork = string

    # Set true to allow traffic from other regions within the same VPC
    global_access = optional(bool, false)

    backends = list(object({
      group           = string
      balancing_mode  = optional(string, "CONNECTION")
      capacity_scaler = optional(number, 1.0)
    }))

    health_check = object({
      name                = string
      protocol            = optional(string, "TCP")
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })
  }))
  default = []

  validation {
    condition     = length(distinct([for lb in var.internal_lbs : lb.key])) == length(var.internal_lbs)
    error_message = "internal_lbs[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for lb in var.internal_lbs : contains(["TCP", "UDP"], lb.protocol)
    ])
    error_message = "internal_lbs[*].protocol must be TCP or UDP."
  }
}
