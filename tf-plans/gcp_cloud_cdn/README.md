# GCP Cloud CDN — Terraform Deployment Plan

This plan calls the [`gcp_cloud_cdn`](../../modules/networking/gcp_cloud_cdn/README.md)
module and provides `terraform.tfvars` examples for both CDN origin types.

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | Compute Engine API, Cloud Storage API |
| IAM | `roles/compute.loadBalancerAdmin` on the project |
| Dependencies | GCS buckets / instance groups must exist before `create = true` |

> Cloud CDN does **not** create a forwarding rule. The backend self-links output
> by this plan must be referenced in a URL map + forwarding rule — use the
> [GCP Cloud Load Balancer plan](../gcp_cloud_load_balancer/README.md).

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Configure the plan
cp terraform.tfvars terraform.auto.tfvars
# Edit terraform.auto.tfvars — update project_id, bucket_name / backend groups

# 3. Initialise and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## CDN Origin Types

| Variable | Origin | Backend Resource |
|----------|--------|-----------------|
| `backend_bucket_cdns` | GCS bucket (static assets) | `google_compute_backend_bucket` |
| `backend_service_cdns` | Instance group / NEG (dynamic) | `google_compute_backend_service` |

Set `create = false` on entries whose origins do not yet exist.

---

## File Reference

| File | Purpose |
|------|---------|
| `main.tf` | Module call |
| `variables.tf` | Input variable declarations |
| `locals.tf` | `created_date` helper |
| `outputs.tf` | Pass-through of all module outputs |
| `providers.tf` | Google provider + Terraform version pin |
| `terraform.tfvars` | Example values for both CDN types |

---

## Key Variables

### `backend_bucket_cdns`

| Field | Default | Description |
|-------|---------|-------------|
| `key` | required | Unique stable map key |
| `create` | `true` | Set `false` to skip without removing |
| `name` | required | Backend bucket resource name |
| `bucket_name` | required | Existing GCS bucket name |
| `cdn_policy.cache_mode` | `CACHE_ALL_STATIC` | `USE_ORIGIN_HEADERS`, `CACHE_ALL_STATIC`, `FORCE_CACHE_ALL` |
| `cdn_policy.default_ttl` | `3600` | Cache TTL when origin has no `max-age` |
| `cdn_policy.negative_caching` | `false` | Cache error responses |
| `cdn_policy.negative_caching_policies` | `[]` | Per-status-code TTL overrides |

### `backend_service_cdns`

| Field | Default | Description |
|-------|---------|-------------|
| `key` | required | Unique stable map key |
| `create` | `true` | Set `false` to skip without removing |
| `name` | required | Backend service resource name |
| `protocol` | `HTTP` | `HTTP`, `HTTPS`, or `HTTP2` |
| `load_balancing_scheme` | `EXTERNAL_MANAGED` | `EXTERNAL_MANAGED` or `EXTERNAL` |
| `backends[].group` | required | Instance group or NEG self-link |
| `health_check.name` | required | Health check resource name |
| `cdn_policy.cache_key_policy.include_query_string` | `true` | Include query string in cache key |
| `cdn_policy.cache_key_policy.include_http_headers` | `[]` | Headers that vary the cache key |

---

## Outputs

| Output | Description |
|--------|-------------|
| `backend_bucket_ids` | Backend bucket resource IDs, keyed by entry key |
| `backend_bucket_self_links` | Backend bucket self-links for URL maps |
| `backend_service_ids` | Backend service resource IDs, keyed by entry key |
| `backend_service_self_links` | Backend service self-links for URL maps |
| `health_check_ids` | Health check IDs for backend service CDN entries |
| `common_labels` | Merged governance labels |

---

## Destroy

```bash
terraform destroy
```

> Backend buckets and backend services are removed. The underlying GCS buckets
> and instance groups are **not** destroyed — they are referenced, not managed,
> by this plan.

---

*Back to [GCP Module Service List](../../gcp-module-service-list.md)*
