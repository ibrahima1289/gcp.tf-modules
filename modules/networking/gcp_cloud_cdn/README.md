# GCP Cloud CDN — Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for [Google Cloud CDN](https://cloud.google.com/cdn/docs) that attaches edge caching to GCS-backed and compute-backed origins. Supports multiple CDN configurations per call, all optional via `create = optional(bool, true)`.

---

## Architecture

```text
                        ┌──────────────────────────────────────────────┐
                        │              Google Global Edge              │
                        │   (Points of Presence — 100+ locations)      │
                        └───────────────┬──────────────────────────────┘
                                        │
                        Cache HIT ◄─────┴────► Cache MISS
                                                    │
                   ┌────────────────────────────────┤
                   │                                │
        ┌──────────▼──────────┐        ┌────────────▼──────────────┐
        │  Backend Bucket CDN │        │  Backend Service CDN      │
        │  (Step 1)           │        │  (Step 2)                 │
        │                     │        │                           │
        │  google_compute_    │        │  google_compute_          │
        │  backend_bucket     │        │  backend_service          │
        │                     │        │  + health_check           │
        └──────────┬──────────┘        └────────────┬──────────────┘
                   │                                │
        ┌──────────▼──────────┐        ┌────────────▼──────────────┐
        │   GCS Bucket        │        │   Instance Groups / NEGs  │
        │   (static assets)   │        │   (dynamic origins)       │
        └─────────────────────┘        └───────────────────────────┘

  Both backend types are consumed by:
    └── google_compute_url_map  →  Target Proxy  →  Forwarding Rule
        (managed by the Cloud Load Balancer module or an existing LB)
```

> **Dependency note**: Cloud CDN is not a standalone service. Backend self-links
> produced by this module are designed to be referenced in a
> [`google_compute_url_map`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map)
> alongside the [GCP Cloud Load Balancer module](../gcp_cloud_load_balancer/README.md).

---

## Resources Created

| Step | Resource | Purpose |
|------|----------|---------|
| 1 | [`google_compute_backend_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket) | Attaches CDN to an existing GCS bucket for static content |
| 2a | [`google_compute_health_check`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | Global health probes for compute-backed CDN origins |
| 2b | [`google_compute_backend_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | Attaches CDN to instance groups or NEGs for dynamic content |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |

### IAM required

| Role | Scope |
|------|-------|
| `roles/compute.loadBalancerAdmin` | Project |
| `roles/storage.objectViewer` | GCS bucket (for backend bucket CDN) |

---

## Usage

### Example 1 — GCS static asset CDN (backend bucket)

```hcl
module "gcp_cloud_cdn" {
  source     = "../../modules/networking/gcp_cloud_cdn"
  project_id = "my-project"

  backend_bucket_cdns = [
    {
      key         = "static-assets"
      create      = true
      name        = "static-assets-cdn"
      bucket_name = "my-static-assets-bucket"
      description = "CDN for static JS/CSS/images"

      cdn_policy = {
        cache_mode  = "CACHE_ALL_STATIC"
        default_ttl = 3600
        max_ttl     = 86400
        client_ttl  = 3600
        negative_caching = true
        negative_caching_policies = [
          { code = 404, ttl = 60 },
          { code = 410, ttl = 120 }
        ]
        cache_key_policy = {
          include_http_headers   = []
          query_string_whitelist = ["v"]   # cache-bust by ?v=<hash>
          query_string_blacklist = []
        }
      }
    }
  ]

  tags = { env = "prod", team = "platform" }
}
```

### Example 2 — Compute / NEG CDN (backend service)

```hcl
module "gcp_cloud_cdn" {
  source     = "../../modules/networking/gcp_cloud_cdn"
  project_id = "my-project"

  backend_service_cdns = [
    {
      key         = "api-cdn"
      create      = true
      name        = "api-cdn-backend"
      description = "CDN for cacheable API responses"
      protocol    = "HTTP"
      load_balancing_scheme = "EXTERNAL_MANAGED"
      enable_logging  = true
      log_sample_rate = 1.0

      backends = [
        {
          group          = "projects/my-project/regions/us-central1/instanceGroups/api-mig"
          balancing_mode = "UTILIZATION"
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
        cache_mode  = "USE_ORIGIN_HEADERS"
        default_ttl = 0        # honour origin Cache-Control
        max_ttl     = 3600
        client_ttl  = 0
        serve_while_stale = 60
        cache_key_policy = {
          include_host         = true
          include_protocol     = true
          include_query_string = false   # strip query string from cache key
          include_http_headers = ["Accept-Language"]
        }
      }
    }
  ]

  tags = { env = "prod", team = "platform" }
}
```

---

## Variables

### Common

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `project_id` | `string` | — | ✅ | GCP project ID for all CDN resources |
| `tags` | `map(string)` | `{}` | ❌ | Governance labels merged with `managed_by` and `created_date` |

---

### `backend_bucket_cdns` — GCS-backed CDN entries

| Field | Type | Default | Required | Description |
|-------|------|---------|:--------:|-------------|
| `key` | `string` | — | ✅ | Unique stable map key |
| `create` | `bool` | `true` | ❌ | Set `false` to skip without removing from config |
| `name` | `string` | — | ✅ | Backend bucket resource name |
| `bucket_name` | `string` | — | ✅ | Existing GCS bucket name |
| `description` | `string` | `""` | ❌ | Human-readable description |
| `cdn_policy.cache_mode` | `string` | `CACHE_ALL_STATIC` | ❌ | `USE_ORIGIN_HEADERS`, `CACHE_ALL_STATIC`, or `FORCE_CACHE_ALL` |
| `cdn_policy.default_ttl` | `number` | `3600` | ❌ | Seconds to cache when no `max-age` header is set |
| `cdn_policy.max_ttl` | `number` | `86400` | ❌ | Maximum TTL regardless of origin headers |
| `cdn_policy.client_ttl` | `number` | `3600` | ❌ | Client-side / downstream proxy TTL |
| `cdn_policy.serve_while_stale` | `number` | `0` | ❌ | Seconds to serve stale while revalidating |
| `cdn_policy.negative_caching` | `bool` | `false` | ❌ | Cache 4xx/5xx error responses |
| `cdn_policy.negative_caching_policies` | `list({code,ttl})` | `[]` | ❌ | Per-status-code TTL overrides |
| `cdn_policy.signed_url_cache_max_age_sec` | `number` | `0` | ❌ | Max age for signed URL cache entries |
| `cdn_policy.cache_key_policy.include_http_headers` | `list(string)` | `[]` | ❌ | HTTP headers that vary the cache key |
| `cdn_policy.cache_key_policy.query_string_whitelist` | `list(string)` | `[]` | ❌ | Query params to include in cache key |
| `cdn_policy.cache_key_policy.query_string_blacklist` | `list(string)` | `[]` | ❌ | Query params to exclude from cache key |

---

### `backend_service_cdns` — Compute/NEG-backed CDN entries

| Field | Type | Default | Required | Description |
|-------|------|---------|:--------:|-------------|
| `key` | `string` | — | ✅ | Unique stable map key |
| `create` | `bool` | `true` | ❌ | Set `false` to skip without removing from config |
| `name` | `string` | — | ✅ | Backend service resource name |
| `description` | `string` | `""` | ❌ | Human-readable description |
| `protocol` | `string` | `HTTP` | ❌ | Backend protocol: `HTTP`, `HTTPS`, `HTTP2` |
| `load_balancing_scheme` | `string` | `EXTERNAL_MANAGED` | ❌ | `EXTERNAL_MANAGED` (Envoy) or `EXTERNAL` (classic) |
| `session_affinity` | `string` | `NONE` | ❌ | Session stickiness: `NONE`, `CLIENT_IP`, `GENERATED_COOKIE` |
| `timeout_sec` | `number` | `30` | ❌ | Backend request timeout in seconds |
| `enable_logging` | `bool` | `false` | ❌ | Enable Cloud Logging for cache hit/miss analysis |
| `log_sample_rate` | `number` | `1.0` | ❌ | Fraction of requests logged (0.0–1.0) |
| `backends[].group` | `string` | — | ✅ | Instance group or NEG self-link |
| `backends[].balancing_mode` | `string` | `UTILIZATION` | ❌ | `UTILIZATION`, `RATE`, or `CONNECTION` |
| `backends[].capacity_scaler` | `number` | `1.0` | ❌ | Fraction of backend capacity used |
| `backends[].max_utilization` | `number` | `0.8` | ❌ | Max CPU utilization (UTILIZATION mode) |
| `backends[].max_rate_per_instance` | `number` | `0` | ❌ | Max RPS per instance (RATE mode; 0 = not set) |
| `health_check.name` | `string` | — | ✅ | Health check resource name |
| `health_check.protocol` | `string` | `HTTP` | ❌ | `HTTP`, `HTTPS`, or `TCP` |
| `health_check.port` | `number` | `80` | ❌ | Port to probe |
| `health_check.request_path` | `string` | `/` | ❌ | HTTP path to probe |
| `health_check.check_interval_sec` | `number` | `10` | ❌ | Seconds between probes |
| `health_check.timeout_sec` | `number` | `5` | ❌ | Probe timeout in seconds |
| `health_check.healthy_threshold` | `number` | `2` | ❌ | Consecutive successes to mark healthy |
| `health_check.unhealthy_threshold` | `number` | `3` | ❌ | Consecutive failures to mark unhealthy |
| `cdn_policy.cache_mode` | `string` | `CACHE_ALL_STATIC` | ❌ | Cache mode (same options as backend bucket) |
| `cdn_policy.cache_key_policy.include_host` | `bool` | `true` | ❌ | Include request hostname in cache key |
| `cdn_policy.cache_key_policy.include_protocol` | `bool` | `true` | ❌ | Include scheme (http/https) in cache key |
| `cdn_policy.cache_key_policy.include_query_string` | `bool` | `true` | ❌ | Include query string in cache key |
| `cdn_policy.cache_key_policy.query_string_whitelist` | `list(string)` | `[]` | ❌ | Query params to include (overrides include_query_string) |
| `cdn_policy.cache_key_policy.query_string_blacklist` | `list(string)` | `[]` | ❌ | Query params to exclude |
| `cdn_policy.cache_key_policy.include_http_headers` | `list(string)` | `[]` | ❌ | Headers that vary the cache key |
| `cdn_policy.cache_key_policy.include_named_cookies` | `list(string)` | `[]` | ❌ | Cookie names that vary the cache key |

---

## Outputs

| Output | Description |
|--------|-------------|
| `backend_bucket_ids` | Backend bucket resource IDs, keyed by entry key |
| `backend_bucket_self_links` | Backend bucket self-links for use in URL maps, keyed by entry key |
| `backend_service_ids` | Backend service resource IDs, keyed by entry key |
| `backend_service_self_links` | Backend service self-links for use in URL maps, keyed by entry key |
| `health_check_ids` | Health check resource IDs for backend service CDN entries, keyed by entry key |
| `common_labels` | Merged governance labels applied to all resources |

---

## Notes

- **Cloud CDN requires a Global External Application LB** — the backend resources created here must be referenced in a `google_compute_url_map` fronted by a `google_compute_global_forwarding_rule`. Use the [GCP Cloud Load Balancer module](../gcp_cloud_load_balancer/README.md) to create the full LB stack.
- **`query_string_whitelist` and `query_string_blacklist` are mutually exclusive** — provide only one per `cache_key_policy` entry.
- **`cache_key_policy.include_host` and `include_protocol`** are only available on backend services, not backend buckets.
- **Signed URLs**: set `signed_url_cache_max_age_sec > 0` and configure IAM permissions separately — this module does not manage signing keys.
- All entries support `create = false` to disable a resource without removing its definition from `terraform.tfvars`.
