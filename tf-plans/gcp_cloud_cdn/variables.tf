variable "project_id" {
  description = "GCP project ID where all Cloud CDN resources are created."
  type        = string
}

variable "tags" {
  description = "Common governance labels applied to all resources."
  type        = map(string)
  default     = {}
}

variable "backend_bucket_cdns" {
  description = "List of GCS-backed Cloud CDN backend bucket configurations."
  type = list(object({
    key         = string
    create      = optional(bool, true)
    name        = string
    bucket_name = string
    description = optional(string, "")

    cdn_policy = optional(object({
      cache_mode        = optional(string, "CACHE_ALL_STATIC")
      default_ttl       = optional(number, 3600)
      max_ttl           = optional(number, 86400)
      client_ttl        = optional(number, 3600)
      serve_while_stale = optional(number, 0)
      negative_caching  = optional(bool, false)
      negative_caching_policies = optional(list(object({
        code = number
        ttl  = number
      })), [])
      signed_url_cache_max_age_sec = optional(number, 0)
      cache_key_policy = optional(object({
        include_http_headers   = optional(list(string), [])
        query_string_whitelist = optional(list(string), [])
        query_string_blacklist = optional(list(string), [])
      }), {})
    }), {})
  }))
  default = []
}

variable "backend_service_cdns" {
  description = "List of compute/NEG-backed Cloud CDN backend service configurations."
  type = list(object({
    key         = string
    create      = optional(bool, true)
    name        = string
    description = optional(string, "")

    protocol              = optional(string, "HTTP")
    load_balancing_scheme = optional(string, "EXTERNAL_MANAGED")
    session_affinity      = optional(string, "NONE")
    timeout_sec           = optional(number, 30)

    enable_logging  = optional(bool, false)
    log_sample_rate = optional(number, 1.0)

    backends = list(object({
      group                 = string
      balancing_mode        = optional(string, "UTILIZATION")
      capacity_scaler       = optional(number, 1.0)
      max_utilization       = optional(number, 0.8)
      max_rate_per_instance = optional(number, 0)
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

    cdn_policy = optional(object({
      cache_mode        = optional(string, "CACHE_ALL_STATIC")
      default_ttl       = optional(number, 3600)
      max_ttl           = optional(number, 86400)
      client_ttl        = optional(number, 3600)
      serve_while_stale = optional(number, 0)
      negative_caching  = optional(bool, false)
      negative_caching_policies = optional(list(object({
        code = number
        ttl  = number
      })), [])
      signed_url_cache_max_age_sec = optional(number, 0)
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
}
