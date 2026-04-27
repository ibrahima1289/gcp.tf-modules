project_id = "my-gcp-project"

tags = {
  env     = "dev"
  team    = "platform"
  owner   = "infra-team"
  project = "my-gcp-project"
}

# ── GCS-backed CDN (backend bucket) ─────────────────────────────────────────
# Use for static content: JS, CSS, images, fonts, compiled build artifacts.
# The GCS bucket must already exist before setting create = true.
backend_bucket_cdns = [
  {
    key         = "static-assets"
    create      = false
    name        = "static-assets-cdn"
    bucket_name = "my-gcp-project-static-assets"
    description = "CDN for JS/CSS/image static assets served from GCS"

    cdn_policy = {
      # CACHE_ALL_STATIC caches common static file types even without cache headers.
      cache_mode  = "CACHE_ALL_STATIC"
      default_ttl = 3600  # 1 hour
      max_ttl     = 86400 # 24 hours
      client_ttl  = 3600

      # Serve stale content for 60s while the edge revalidates in the background.
      serve_while_stale = 60

      # Cache 404s for 60s and 410s for 120s to reduce origin hammering.
      negative_caching = true
      negative_caching_policies = [
        { code = 404, ttl = 60 },
        { code = 410, ttl = 120 }
      ]

      cache_key_policy = {
        # Whitelist ?v= for cache-busting; all other query params are ignored.
        query_string_whitelist = ["v"]
        query_string_blacklist = []
        include_http_headers   = []
      }
    }
  },

  {
    # Second example: video / large media files with long TTLs.
    key         = "media-cdn"
    create      = false
    name        = "media-cdn"
    bucket_name = "my-gcp-project-media"
    description = "CDN for video and large media files"

    cdn_policy = {
      cache_mode        = "FORCE_CACHE_ALL"
      default_ttl       = 86400  # 24 hours
      max_ttl           = 604800 # 7 days
      client_ttl        = 86400
      serve_while_stale = 300
      negative_caching  = false
      cache_key_policy  = {}
    }
  }
]

# ── Compute / NEG-backed CDN (backend service) ───────────────────────────────
# Use for dynamic origins (MIGs, NEGs) that produce cacheable responses.
# The instance group or NEG must already exist before setting create = true.
backend_service_cdns = [
  {
    key                   = "api-cdn"
    create                = false
    name                  = "api-cdn-backend"
    description           = "CDN-accelerated API backend for cacheable GET responses"
    protocol              = "HTTP"
    load_balancing_scheme = "EXTERNAL_MANAGED"
    timeout_sec           = 30
    enable_logging        = true
    log_sample_rate       = 1.0

    backends = [
      {
        group           = "projects/my-gcp-project/regions/us-central1/instanceGroups/api-mig"
        balancing_mode  = "UTILIZATION"
        max_utilization = 0.8
      }
    ]

    health_check = {
      name         = "api-cdn-hc"
      protocol     = "HTTP"
      port         = 8080
      request_path = "/healthz"
    }

    cdn_policy = {
      # Respect Cache-Control headers from the API; cache only when origin says so.
      cache_mode  = "USE_ORIGIN_HEADERS"
      default_ttl = 0 # honour origin headers
      max_ttl     = 3600
      client_ttl  = 0

      # Serve stale for 30s during revalidation.
      serve_while_stale = 30

      cache_key_policy = {
        include_host     = true
        include_protocol = true
        # Strip query string — all query variations share one cache entry.
        include_query_string = false
        # Vary cache by Accept-Language for localised responses.
        include_http_headers  = ["Accept-Language"]
        include_named_cookies = []
      }
    }
  }
]
