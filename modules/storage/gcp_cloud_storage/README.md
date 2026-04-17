# GCP Cloud Storage Terraform Module

Reusable Terraform module for creating one or many [Google Cloud Storage](https://cloud.google.com/storage/docs) buckets with full lifecycle management, versioning, CMEK encryption, CORS, static website hosting, access logging, autoclass, and soft-delete policy controls.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "cloud_storage"
└── google_storage_bucket.bucket          (one per buckets[] entry)
    ├── versioning {}
    ├── soft_delete_policy {}
    ├── dynamic autoclass {}               (when autoclass_enabled = true)
    ├── dynamic encryption {}              (when default_kms_key_name is set)
    ├── dynamic lifecycle_rule {}          (one per lifecycle_rules[] entry)
    ├── dynamic cors {}                    (one per cors[] entry)
    ├── dynamic logging {}                 (when log_bucket is set)
    └── dynamic website {}                 (when website_main_page_suffix is set)
```

Data flow:

```text
var.buckets[] + var.project_id + var.region + var.tags
            ↓
locals.buckets_map  ← project/location resolved, labels merged
            ↓
google_storage_bucket.bucket[key]
            ↓
Outputs: bucket_ids, bucket_urls, bucket_names, bucket_self_links
```

---

## Requirements

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |

---

## Resources

| Resource | Purpose |
|----------|---------|
| [`google_storage_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | Creates and configures each Cloud Storage bucket |
| [`google_storage_bucket_object_retention`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object_retention) | Applies object retention policy when configured |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default GCP project ID for buckets that do not override `project_id`. |
| `buckets` | `list(object)` | One or many bucket definitions. See [`buckets` object fields](#buckets-object-fields). |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default location for buckets that do not set `location`. |
| `tags` | `map(string)` | `{}` | Common governance tags merged into every bucket's labels. |

---

## `buckets` Object Fields

### Core Identity

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable unique key used for `for_each`. Must be unique. |
| `name` | `string` | ✅ | — | Globally unique bucket name. |
| `project_id` | `string` | | `""` | Per-bucket project override. Falls back to `var.project_id`. |
| `location` | `string` | | `""` | Region, dual-region, or multi-region. Falls back to `var.region`. |
| `storage_class` | `string` | | `"STANDARD"` | `STANDARD`, `NEARLINE`, `COLDLINE`, or `ARCHIVE`. |
| `labels` | `map(string)` | | `{}` | Additional labels merged on top of common tags. |

### Access and Safety

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `uniform_bucket_level_access` | `bool` | | `true` | Disables object-level ACLs. Recommended `true`. |
| `public_access_prevention` | `string` | | `"enforced"` | `enforced` blocks all public access; `inherited` inherits org policy. |
| `force_destroy` | `bool` | | `false` | Allows `terraform destroy` on non-empty buckets. Use with caution. |
| `default_event_based_hold` | `bool` | | `false` | Applies event-based hold to all new objects. |
| `requester_pays` | `bool` | | `false` | Requester pays for access and download costs. |

### Versioning and Soft-Delete

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `versioning_enabled` | `bool` | | `false` | Keeps full version history of every object. |
| `soft_delete_policy_retention_duration_seconds` | `number` | | `604800` | Soft-delete retention window in seconds. Set `0` to disable. |

### Lifecycle Rules

Each item in `lifecycle_rules` is one rule:

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `action_type` | `string` | ✅ | — | `Delete` or `SetStorageClass`. |
| `action_storage_class` | `string` | ✅ for `SetStorageClass` | `""` | Target storage class for `SetStorageClass` actions. |
| `condition_age` | `number` | | `null` | Trigger when object age in days meets threshold. |
| `condition_created_before` | `string` | | `null` | Trigger for objects created before this RFC 3339 date. |
| `condition_with_state` | `string` | | `null` | `LIVE`, `ARCHIVED`, or `ANY`. |
| `condition_matches_storage_class` | `list(string)` | | `null` | Trigger for objects in these storage classes. |
| `condition_matches_prefix` | `list(string)` | | `null` | Trigger for objects with these name prefixes. |
| `condition_matches_suffix` | `list(string)` | | `null` | Trigger for objects with these name suffixes. |
| `condition_num_newer_versions` | `number` | | `null` | Trigger when object has this many newer versions. |
| `condition_days_since_noncurrent_time` | `number` | | `null` | Trigger N days after object becomes non-current. |

### Encryption (CMEK)

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `default_kms_key_name` | `string` | | `""` | Cloud KMS key resource name for default object encryption. Empty = Google-managed keys. |

### Logging

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `log_bucket` | `string` | | `""` | Target bucket to receive GCS access logs. Empty = logging disabled. |
| `log_object_prefix` | `string` | | `""` | Object prefix for log entries. Defaults to the bucket name. |

### Website Hosting

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `website_main_page_suffix` | `string` | | `""` | Default page served for `/` requests (e.g., `index.html`). |
| `website_not_found_page` | `string` | | `""` | Page served for 404 responses. |

### Autoclass

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `autoclass_enabled` | `bool` | | `false` | Automatically transitions objects to cost-optimal storage class. |
| `autoclass_terminal_storage_class` | `string` | | `"NEARLINE"` | Lowest class autoclass transitions to. `NEARLINE` or `ARCHIVE`. |

### Retention Policy

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `retention_policy_is_locked` | `bool` | | `false` | When `true`, locks the retention policy permanently. |
| `retention_policy_retention_period` | `number` | | `null` | Retention duration in seconds. `null` = no retention policy. |

### CORS

Each item in `cors` is one CORS rule:

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `origin` | `list(string)` | ✅ | — | Allowed origin domains. |
| `method` | `list(string)` | ✅ | — | Allowed HTTP methods (e.g., `GET`, `POST`). |
| `response_header` | `list(string)` | | `[]` | Allowed response headers. |
| `max_age_seconds` | `number` | | `3600` | Browser cache duration for preflight responses. |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `bucket_ids` | `map(string)` | Bucket resource IDs keyed by bucket key. |
| `bucket_names` | `map(string)` | Bucket names keyed by bucket key. |
| `bucket_urls` | `map(string)` | `gs://` URLs keyed by bucket key. |
| `bucket_self_links` | `map(string)` | REST API self-link URIs keyed by bucket key. |
| `bucket_locations` | `map(string)` | Resolved bucket locations keyed by bucket key. |
| `bucket_projects` | `map(string)` | Resolved project IDs keyed by bucket key. |
| `bucket_storage_classes` | `map(string)` | Storage class per bucket, keyed by bucket key. |
| `versioning_enabled` | `map(bool)` | Versioning state per bucket, keyed by bucket key. |
| `common_tags` | `map(string)` | Governance tags generated by this module call. |

---

## Usage Example

```hcl
module "cloud_storage" {
  source = "../../modules/storage/gcp_cloud_storage"

  project_id = "my-data-project"
  region     = "us-central1"

  tags = {
    owner       = "data-platform"
    environment = "production"
    team        = "analytics"
  }

  buckets = [
    # Standard data lake bucket with versioning and lifecycle management
    {
      key           = "data-lake"
      name          = "my-company-data-lake-prod"
      location      = "US"
      storage_class = "STANDARD"

      versioning_enabled          = true
      uniform_bucket_level_access = true
      public_access_prevention    = "enforced"

      lifecycle_rules = [
        {
          action_type          = "SetStorageClass"
          action_storage_class = "NEARLINE"
          condition_age        = 30
        },
        {
          action_type   = "Delete"
          condition_age = 365
          condition_with_state = "ARCHIVED"
          condition_num_newer_versions = 3
        }
      ]
    },
    # Static website bucket
    {
      key                      = "website"
      name                     = "my-company-static-site"
      location                 = "us-central1"
      storage_class            = "STANDARD"
      public_access_prevention = "inherited"

      website_main_page_suffix = "index.html"
      website_not_found_page   = "404.html"

      cors = [
        {
          origin          = ["https://example.com"]
          method          = ["GET", "HEAD"]
          response_header = ["Content-Type"]
          max_age_seconds = 3600
        }
      ]
    },
    # CMEK-encrypted bucket for sensitive data
    {
      key                  = "sensitive"
      name                 = "my-company-sensitive-data"
      location             = "us-central1"
      storage_class        = "STANDARD"
      default_kms_key_name = "projects/my-data-project/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key"

      soft_delete_policy_retention_duration_seconds = 2592000 # 30 days

      log_bucket        = "my-company-access-logs"
      log_object_prefix = "sensitive-bucket/"
    }
  ]
}
```

---

## Validation Behavior

- `buckets[*].key` values must be unique across the list.
- `buckets[*].name` values must be unique across the list.
- `storage_class` must be `STANDARD`, `NEARLINE`, `COLDLINE`, or `ARCHIVE`.
- `public_access_prevention` must be `enforced` or `inherited`.
- `lifecycle_rules[*].action_type` must be `Delete` or `SetStorageClass`.
- `action_storage_class` is required when `action_type = "SetStorageClass"`.

---

## Related Docs

- [Cloud Storage Overview](https://cloud.google.com/storage/docs/introduction)
- [Cloud Storage Pricing](https://cloud.google.com/storage/pricing)
- [Lifecycle Management](https://cloud.google.com/storage/docs/lifecycle)
- [CMEK for Cloud Storage](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys)
- [Cloud Storage Deployment Plan](../../../tf-plans/gcp_cloud_storage/README.md)
- [Cloud Storage Service Explainer](./gcp-cloud-storage.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
