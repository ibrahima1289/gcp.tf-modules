# ===========================================================================
# Step 1: Backend Bucket CDN configurations (GCS-backed static origins)
# google_compute_backend_bucket attaches Cloud CDN directly to a GCS bucket.
# Use this for static assets: images, JS/CSS, video files, compiled artifacts.
# ===========================================================================

# 1a: Create backend bucket resources with CDN enabled.
# Each entry maps a GCS bucket to a backend bucket that Cloud CDN can cache.
# The bucket must already exist; only its name is referenced here.
resource "google_compute_backend_bucket" "cdn" {
  for_each = { for e in var.backend_bucket_cdns : e.key => e if e.create }

  project     = var.project_id
  name        = each.value.name
  bucket_name = each.value.bucket_name
  description = each.value.description
  enable_cdn  = true

  # 1b: CDN caching policy — controls TTL, cache mode, and cache key behaviour.
  cdn_policy {
    cache_mode                   = each.value.cdn_policy.cache_mode
    default_ttl                  = each.value.cdn_policy.default_ttl
    max_ttl                      = each.value.cdn_policy.max_ttl
    client_ttl                   = each.value.cdn_policy.client_ttl
    negative_caching             = each.value.cdn_policy.negative_caching
    serve_while_stale            = each.value.cdn_policy.serve_while_stale
    signed_url_cache_max_age_sec = each.value.cdn_policy.signed_url_cache_max_age_sec

    # Cache key policy for backend buckets supports header and query string filtering.
    # Note: backend buckets do not support include_host / include_protocol fields.
    cache_key_policy {
      include_http_headers   = each.value.cdn_policy.cache_key_policy.include_http_headers
      query_string_whitelist = each.value.cdn_policy.cache_key_policy.query_string_whitelist
    }

    # Negative caching policies define per-status-code TTLs for error responses.
    dynamic "negative_caching_policy" {
      for_each = each.value.cdn_policy.negative_caching ? each.value.cdn_policy.negative_caching_policies : []
      content {
        code = negative_caching_policy.value.code
        ttl  = negative_caching_policy.value.ttl
      }
    }
  }
}

# ===========================================================================
# Step 2: Backend Service CDN configurations (compute / NEG-backed origins)
# google_compute_backend_service attaches Cloud CDN to compute instance groups
# or NEGs. Suitable for dynamic content that can still benefit from edge caching.
# ===========================================================================

# 2a: Global health checks for each backend service CDN entry.
# Health checks run from Google's global probing infrastructure every
# check_interval_sec seconds to determine which instances receive traffic.
resource "google_compute_health_check" "backend_service_cdn" {
  for_each = { for e in var.backend_service_cdns : e.key => e if e.create }

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

# 2b: Global backend services with CDN enabled.
# Each backend service maps one or more instance groups or NEGs to Cloud CDN.
# The load_balancing_scheme must be EXTERNAL_MANAGED or EXTERNAL.
resource "google_compute_backend_service" "cdn" {
  for_each = { for e in var.backend_service_cdns : e.key => e if e.create }

  project               = var.project_id
  name                  = each.value.name
  description           = each.value.description
  protocol              = each.value.protocol
  load_balancing_scheme = each.value.load_balancing_scheme
  session_affinity      = each.value.session_affinity
  timeout_sec           = each.value.timeout_sec
  enable_cdn            = true

  health_checks = [google_compute_health_check.backend_service_cdn[each.key].id]

  # Each backend references one instance group or NEG by self-link.
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

  # 2c: CDN caching policy for compute-backed origins.
  cdn_policy {
    cache_mode                   = each.value.cdn_policy.cache_mode
    default_ttl                  = each.value.cdn_policy.default_ttl
    max_ttl                      = each.value.cdn_policy.max_ttl
    client_ttl                   = each.value.cdn_policy.client_ttl
    negative_caching             = each.value.cdn_policy.negative_caching
    serve_while_stale            = each.value.cdn_policy.serve_while_stale
    signed_url_cache_max_age_sec = each.value.cdn_policy.signed_url_cache_max_age_sec

    cache_key_policy {
      include_host           = each.value.cdn_policy.cache_key_policy.include_host
      include_protocol       = each.value.cdn_policy.cache_key_policy.include_protocol
      include_query_string   = each.value.cdn_policy.cache_key_policy.include_query_string
      query_string_whitelist = each.value.cdn_policy.cache_key_policy.include_query_string ? each.value.cdn_policy.cache_key_policy.query_string_whitelist : []
      query_string_blacklist = each.value.cdn_policy.cache_key_policy.include_query_string ? each.value.cdn_policy.cache_key_policy.query_string_blacklist : []
      include_http_headers   = each.value.cdn_policy.cache_key_policy.include_http_headers
      include_named_cookies  = each.value.cdn_policy.cache_key_policy.include_named_cookies
    }

    dynamic "negative_caching_policy" {
      for_each = each.value.cdn_policy.negative_caching ? each.value.cdn_policy.negative_caching_policies : []
      content {
        code = negative_caching_policy.value.code
        ttl  = negative_caching_policy.value.ttl
      }
    }
  }

  # Optional: access logging to Cloud Logging for cache hit/miss analysis.
  dynamic "log_config" {
    for_each = each.value.enable_logging ? [1] : []
    content {
      enable      = true
      sample_rate = each.value.log_sample_rate
    }
  }
}
