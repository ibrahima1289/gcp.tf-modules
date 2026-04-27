# ---------------------------------------------------------------------------
# Default project for all Cloud CDN resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID where all Cloud CDN resources are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Common governance labels applied to all resources.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date in locals."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# CDN policy object type — reused by both backend bucket and backend service
# variables. Defined once here for documentation clarity.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Backend Bucket CDN configurations (GCS-backed static origins)
# Each entry manages one google_compute_backend_bucket with CDN enabled.
# The GCS bucket must already exist; only its name is referenced.
# ---------------------------------------------------------------------------
variable "backend_bucket_cdns" {
  description = "List of GCS-backed Cloud CDN backend bucket configurations. Each entry creates one google_compute_backend_bucket with CDN enabled."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry in tfvars for reference.
    create = optional(bool, true)
    # Name of the google_compute_backend_bucket resource.
    name = string
    # Existing GCS bucket name to attach CDN to.
    bucket_name = string
    # Human-readable description for the backend bucket.
    description = optional(string, "")

    # CDN caching policy — controls how responses are cached at Google edge PoPs.
    cdn_policy = optional(object({
      # USE_ORIGIN_HEADERS: respect Cache-Control from origin.
      # CACHE_ALL_STATIC: cache static file types even without cache headers.
      # FORCE_CACHE_ALL: cache all successful responses regardless of headers.
      cache_mode = optional(string, "CACHE_ALL_STATIC")

      # Time in seconds to serve a cached response if no max-age is set (default TTL).
      default_ttl = optional(number, 3600)
      # Maximum TTL enforced regardless of origin Cache-Control max-age.
      max_ttl = optional(number, 86400)
      # TTL for client-side caching (browser / downstream proxy).
      client_ttl = optional(number, 3600)

      # Serve a stale cached response for this many seconds while revalidating.
      serve_while_stale = optional(number, 0)

      # Enable negative caching (cache 4xx/5xx responses for short TTLs).
      negative_caching = optional(bool, false)
      # Per-status-code TTL overrides when negative_caching = true.
      negative_caching_policies = optional(list(object({
        code = number # HTTP status code (e.g. 404, 410)
        ttl  = number # Seconds to cache this error response
      })), [])

      # Max age for signed URLs in the CDN cache; 0 disables signed URL caching.
      signed_url_cache_max_age_sec = optional(number, 0)

      # Cache key policy for backend buckets.
      # Note: include_host and include_protocol are not supported by backend buckets.
      cache_key_policy = optional(object({
        # HTTP headers to include in the cache key (adds per-header cache entries).
        include_http_headers = optional(list(string), [])
        # Whitelist of query string params to include (empty = include all or none).
        query_string_whitelist = optional(list(string), [])
        # Blacklist of query string params to exclude from the cache key.
        query_string_blacklist = optional(list(string), [])
      }), {})
    }), {})
  }))
  default = []

  validation {
    condition     = length(var.backend_bucket_cdns) == length(distinct([for e in var.backend_bucket_cdns : e.key]))
    error_message = "Each entry in backend_bucket_cdns must have a unique key."
  }
}

# ---------------------------------------------------------------------------
# Backend Service CDN configurations (compute / NEG-backed dynamic origins)
# Each entry creates one google_compute_health_check + google_compute_backend_service
# with CDN enabled. Must use EXTERNAL_MANAGED or EXTERNAL load_balancing_scheme.
# ---------------------------------------------------------------------------
variable "backend_service_cdns" {
  description = "List of compute/NEG-backed Cloud CDN backend service configurations. Each entry creates one global backend service with CDN enabled."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry in tfvars for reference.
    create = optional(bool, true)
    # Name of the google_compute_backend_service resource.
    name = string
    # Human-readable description.
    description = optional(string, "")

    # Backend protocol exposed to Cloud CDN and the target proxy.
    protocol = optional(string, "HTTP") # HTTP, HTTPS, HTTP2
    # Must be EXTERNAL_MANAGED (Envoy-based) or EXTERNAL (classic GFE).
    load_balancing_scheme = optional(string, "EXTERNAL_MANAGED")
    # Session affinity for CDN backends (usually NONE; CDN handles distribution).
    session_affinity = optional(string, "NONE")
    # Backend request timeout in seconds.
    timeout_sec = optional(number, 30)

    # Enable Cloud Logging — records cache hit/miss, latency, and status per request.
    enable_logging  = optional(bool, false)
    log_sample_rate = optional(number, 1.0)

    # One or more instance groups or NEGs that serve origin traffic.
    backends = list(object({
      group                 = string                          # self-link of instance group or NEG
      balancing_mode        = optional(string, "UTILIZATION") # UTILIZATION, RATE, CONNECTION
      capacity_scaler       = optional(number, 1.0)
      max_utilization       = optional(number, 0.8) # used with UTILIZATION mode
      max_rate_per_instance = optional(number, 0)   # used with RATE mode; 0 = not set
    }))

    # Health check configuration for the backend service.
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

    # CDN caching policy for compute-backed origins.
    cdn_policy = optional(object({
      cache_mode  = optional(string, "CACHE_ALL_STATIC")
      default_ttl = optional(number, 3600)
      max_ttl     = optional(number, 86400)
      client_ttl  = optional(number, 3600)

      serve_while_stale = optional(number, 0)
      negative_caching  = optional(bool, false)
      negative_caching_policies = optional(list(object({
        code = number
        ttl  = number
      })), [])
      signed_url_cache_max_age_sec = optional(number, 0)

      # Full cache key policy supported by backend services.
      cache_key_policy = optional(object({
        include_host           = optional(bool, true)
        include_protocol       = optional(bool, true)
        include_query_string   = optional(bool, true)
        query_string_whitelist = optional(list(string), [])
        query_string_blacklist = optional(list(string), [])
        include_http_headers   = optional(list(string), [])
        include_named_cookies  = optional(list(string), [])
      }), {})
    }), {})
  }))
  default = []

  validation {
    condition     = length(var.backend_service_cdns) == length(distinct([for e in var.backend_service_cdns : e.key]))
    error_message = "Each entry in backend_service_cdns must have a unique key."
  }
}
