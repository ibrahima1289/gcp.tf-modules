# GCP App Engine Terraform Module

Reusable Terraform module for managing Google App Engine applications, standard and flexible service versions, traffic splits, firewall rules, and custom domain mappings.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md) · [App Engine Explainer](gcp-app-engine.md)

---

## Architecture

```text
modules/compute/gcp_app_engine/
├── main.tf          → Resource definitions (application, versions, splits, firewall, domains)
├── variables.tf     → Input variable declarations with validations
├── locals.tf        → created_date, common_tags, service/firewall/domain maps
├── outputs.tf       → Application URL, version names, DNS records
├── providers.tf     → Terraform ≥ 1.5, Google provider ≥ 6.0
├── README.md        → This file
└── gcp-app-engine.md → Service explainer

                         App Engine Application  (singleton per project)
                                  │
           ┌──────────────────────┼───────────────────────┐
           │                      │                       │
google_app_engine_        google_app_engine_    google_app_engine_
standard_app_version      flexible_app_version  application_url_
   (for_each key)            (for_each key)     dispatch_rules
           │                      │
           └──────────┬───────────┘
                      │
        google_app_engine_service_split_traffic
              (canary / blue-green rollout)
                      │
        google_app_engine_firewall_rule   (for_each key)
        google_app_engine_domain_mapping  (for_each key)
```

### Data Flow

1. `google_app_engine_application` is created once per project (singleton). `location_id` is **permanent** — changing it requires deleting and recreating the entire application.
2. Standard and flexible versions are in **separate resource blocks** to avoid provider-level argument conflicts (`liveness_check`, `readiness_check`, `resources` are flexible-only).
3. Traffic is split per service via `google_app_engine_service_split_traffic`, allowing canary and blue/green rollouts without code changes.
4. `noop_on_destroy = true` (default) prevents Terraform destroy from deleting App Engine versions — versions accumulate and you manage which ones receive traffic via split.
5. Firewall rules are evaluated in **ascending priority order** — the rule with the lowest priority number wins.

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP API | `appengine.googleapis.com` |
| IAM role | `roles/appengine.appAdmin` |

---

## Resources Created

| Resource | When |
|----------|------|
| `google_app_engine_application` | `application.create = true` |
| `google_app_engine_application_url_dispatch_rules` | `length(dispatch_rules) > 0` |
| `google_app_engine_standard_app_version` | `services[*].env_type = "standard"` and `create = true` |
| `google_app_engine_flexible_app_version` | `services[*].env_type = "flexible"` and `create = true` |
| `google_app_engine_service_split_traffic` | `services[*].traffic_split_enabled = true` |
| `google_app_engine_firewall_rule` | `firewall_rules[*].create = true` |
| `google_app_engine_domain_mapping` | `domain_mappings[*].create = true` |

---

## Variables

### Top-level

| Variable | Type | Required | Default | Description |
|----------|------|:--------:|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID |
| `region` | `string` | | `us-central1` | Interface consistency; location is set per `application.location_id` |
| `tags` | `map(string)` | | `{}` | Common governance labels |
| `application` | `object` | | see below | App Engine application (singleton) |
| `services` | `list(object)` | | `[]` | One or many service versions |
| `firewall_rules` | `list(object)` | | `[]` | Firewall rules for inbound access |
| `domain_mappings` | `list(object)` | | `[]` | Custom domain mappings |
| `dispatch_rules` | `list(object)` | | `[]` | URL dispatch rules per service |

---

### `application` object

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `location_id` | `string` | ✅ | — | App Engine region (e.g. `us-central`, `us-east1`). **Permanent after creation.** |
| `create` | `bool` | | `true` | Set `false` to skip creation (app already exists) |
| `serving_status` | `string` | | `SERVING` | `SERVING` · `USER_DISABLED` · `SYSTEM_DISABLED` |
| `database_type` | `string` | | `CLOUD_FIRESTORE` | `CLOUD_DATASTORE` · `CLOUD_FIRESTORE` · `CLOUD_DATASTORE_COMPATIBILITY` |
| `auth_domain` | `string` | | `""` | Custom G Suite authentication domain |
| `iap_enabled` | `bool` | | `false` | Enable Identity-Aware Proxy |
| `iap_oauth2_client_id` | `string` | | `""` | IAP OAuth2 client ID (required when iap_enabled = true) |
| `iap_oauth2_client_secret` | `string` | | `""` | IAP OAuth2 client secret |
| `feature_settings_split_health_checks` | `bool` | | `true` | Enable split health checks to reduce deployment downtime |

---

### `services[]` object — common fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable Terraform identifier (unique across all services) |
| `service` | `string` | ✅ | — | App Engine service name (e.g. `default`, `api`, `worker`) |
| `runtime` | `string` | ✅ | — | Runtime ID (e.g. `python312`, `nodejs20`, `go122`, `custom`) |
| `env_type` | `string` | | `standard` | `standard` or `flexible` |
| `version_id` | `string` | | `v1` | Immutable version identifier |
| `create` | `bool` | | `true` | Set `false` to skip this entry |
| `project_id` | `string` | | `""` | Per-service project override (falls back to `var.project_id`) |
| `deployment_type` | `string` | | `zip` | `zip` · `files` · `container` (flexible only) |
| `deployment_zip_source_url` | `string` | ✅ if zip | `""` | GCS URL for the deployment ZIP (e.g. `https://storage.googleapis.com/bucket/app.zip`) |
| `deployment_zip_files_count` | `number` | | `0` | File count hint in the ZIP for validation |
| `deployment_container_image` | `string` | ✅ if container | `""` | Container image URL (flexible + deployment_type=container) |
| `deployment_files` | `list(object)` | ✅ if files | `[]` | Individual deployment files: `name`, `source_url`, `sha1_sum` |
| `entrypoint_shell` | `string` | | `""` | Shell command to start the service |
| `env_variables` | `map(string)` | | `{}` | Runtime environment variables |
| `inbound_services` | `list(string)` | | `[]` | Enabled inbound services (e.g. `INBOUND_SERVICE_WARMUP`) |
| `scaling_type` | `string` | | `automatic` | `automatic` · `basic` (standard only) · `manual` |
| `traffic_split_enabled` | `bool` | | `false` | Create a traffic split resource for this service |
| `traffic_split_shard_by` | `string` | | `RANDOM` | `COOKIE` · `IP` · `RANDOM` |
| `traffic_allocations` | `map(string)` | ✅ if split | `{}` | Version weights: `{ "v1" = "0.8", "v2" = "0.2" }` |
| `noop_on_destroy` | `bool` | | `true` | Skip destroy on `terraform destroy` (recommended) |
| `delete_service_on_destroy` | `bool` | | `false` | Delete the entire service on destroy |

---

### `services[]` — automatic scaling fields (standard)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `max_concurrent_requests` | `number` | `10` | Max concurrent requests per instance |
| `max_idle_instances` | `number` | `1` | Max idle instances kept warm |
| `max_pending_latency` | `string` | `automatic` | Max pending latency before scaling up |
| `min_idle_instances` | `number` | `0` | Min idle instances (0 = scale to zero) |
| `min_pending_latency` | `string` | `30ms` | Min pending latency before scaling up |
| `target_cpu_utilization` | `number` | `0.6` | Target CPU utilization (0.0–1.0) |
| `target_throughput_utilization` | `number` | `0.6` | Target throughput utilization |
| `min_instances` | `number` | `0` | Minimum instances (standard scheduler) |
| `max_instances` | `number` | `10` | Maximum instances (standard scheduler) |

---

### `services[]` — standard environment fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `instance_class` | `string` | `F1` | `F1`·`F2`·`F4`·`F4_1G` (auto-scale) or `B1`·`B2`·`B4`·`B4_1G`·`B8` (basic/manual) |
| `threadsafe` | `bool` | `true` | Whether the app is thread-safe (Python only) |
| `runtime_api_version` | `string` | `""` | Runtime API version (deprecated for runtimes ≥ Python 3) |
| `basic_scaling_idle_timeout` | `string` | `5m` | Idle timeout before instance shutdown (basic scaling) |
| `basic_scaling_max_instances` | `number` | `5` | Max instances for basic scaling |
| `manual_scaling_instances` | `number` | `1` | Fixed number of instances for manual scaling |

---

### `services[]` — flexible environment fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `resources_cpu` | `number` | `1` | Number of CPU cores |
| `resources_disk_gb` | `number` | `10` | Disk size in GB |
| `resources_memory_gb` | `number` | `0.6` | Memory in GB |
| `liveness_check_path` | `string` | `/` | Liveness check HTTP path |
| `liveness_check_initial_delay` | `string` | `300s` | Delay before first liveness check |
| `liveness_check_check_interval` | `string` | `30s` | Interval between liveness checks |
| `liveness_check_timeout` | `string` | `4s` | Liveness check timeout |
| `liveness_check_failure_threshold` | `number` | `4` | Failures before restart |
| `liveness_check_success_threshold` | `number` | `2` | Successes to be considered healthy |
| `readiness_check_path` | `string` | `/` | Readiness check HTTP path |
| `readiness_check_check_interval` | `string` | `5s` | Interval between readiness checks |
| `readiness_check_timeout` | `string` | `4s` | Readiness check timeout |
| `readiness_check_failure_threshold` | `number` | `2` | Failures before traffic is held back |
| `readiness_check_success_threshold` | `number` | `2` | Successes before traffic is routed |
| `readiness_check_app_start_timeout` | `string` | `300s` | Max time to wait for instance startup |
| `flex_cool_down_period` | `string` | `120s` | Scaling cool-down period |
| `flex_aggregation_window_length` | `string` | `60s` | CPU utilization averaging window |
| `min_instances` | `number` | `0` | Min total instances (flexible auto-scaling) |
| `max_instances` | `number` | `10` | Max total instances (flexible auto-scaling) |

---

### `firewall_rules[]` object

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable Terraform identifier |
| `priority` | `number` | ✅ | — | Rule priority (1–2147483646); lower number = higher precedence |
| `action` | `string` | ✅ | — | `ALLOW` or `DENY` |
| `source_range` | `string` | ✅ | — | CIDR range or `*` for all |
| `description` | `string` | | `""` | Human-readable description |
| `create` | `bool` | | `true` | Set `false` to skip this rule |

---

### `domain_mappings[]` object

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable Terraform identifier |
| `domain_name` | `string` | ✅ | — | Custom domain (e.g. `www.example.com`) |
| `override_strategy` | `string` | | `STRICT` | `STRICT` (error if mapping exists) or `OVERRIDE` |
| `ssl_management_type` | `string` | | `AUTOMATIC` | `AUTOMATIC` or `MANUAL` |
| `ssl_certificate_id` | `string` | | `""` | Certificate ID for manual SSL management |
| `create` | `bool` | | `true` | Set `false` to skip this mapping |

---

### `dispatch_rules[]` object

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `domain` | `string` | ✅ | Domain pattern (e.g. `*.example.com`) |
| `path` | `string` | ✅ | URL path pattern (e.g. `/api/*`) |
| `service` | `string` | ✅ | Target service name |

---

## Outputs

| Output | Description |
|--------|-------------|
| `application_id` | Application ID (matches project ID) |
| `application_name` | Fully-qualified name `apps/{project}` |
| `application_url` | Default HTTPS URL `https://{project}.appspot.com` |
| `default_hostname` | Default hostname `{project}.appspot.com` |
| `default_bucket` | Default GCS staging bucket |
| `standard_version_ids` | Standard version IDs keyed by service key |
| `standard_version_names` | Fully-qualified standard version names |
| `flexible_version_ids` | Flexible version IDs keyed by service key |
| `flexible_version_names` | Fully-qualified flexible version names |
| `split_traffic_ids` | Traffic split resource IDs |
| `firewall_rule_ids` | Firewall rule IDs keyed by rule key |
| `domain_mapping_ids` | Domain mapping IDs keyed by mapping key |
| `domain_mapping_resource_records` | DNS records to add to your DNS provider |
| `common_tags` | Common governance tags used in this call |

---

## Usage Examples

### Standard Python service with automatic scaling

```hcl
module "app_engine" {
  source     = "../../modules/compute/gcp_app_engine"
  project_id = "my-project"

  application = {
    location_id = "us-central"
  }

  tags = { environment = "production", team = "platform" }

  services = [
    {
      key     = "default-web"
      service = "default"
      runtime = "python312"

      deployment_type           = "zip"
      deployment_zip_source_url = "https://storage.googleapis.com/my-bucket/app.zip"

      scaling_type           = "automatic"
      min_instances          = 0
      max_instances          = 5
      target_cpu_utilization = 0.6

      env_variables = { LOG_LEVEL = "INFO" }
    }
  ]
}
```

---

### Multi-service application with traffic split (canary deploy)

```hcl
module "app_engine" {
  source     = "../../modules/compute/gcp_app_engine"
  project_id = "my-project"

  application = { location_id = "us-central" }

  services = [
    # Stable version receives 90% of traffic
    {
      key        = "api-v1"
      service    = "api"
      runtime    = "nodejs20"
      version_id = "v1"

      deployment_type           = "zip"
      deployment_zip_source_url = "https://storage.googleapis.com/my-bucket/api-v1.zip"

      # Traffic split sends 90% here, 10% to v2
      traffic_split_enabled  = true
      traffic_split_shard_by = "COOKIE"
      traffic_allocations    = { "v1" = "0.9", "v2" = "0.1" }
    },
    # Canary version receives 10% of traffic
    {
      key        = "api-v2"
      service    = "api"
      runtime    = "nodejs20"
      version_id = "v2"

      deployment_type           = "zip"
      deployment_zip_source_url = "https://storage.googleapis.com/my-bucket/api-v2.zip"

      # Split is controlled by the v1 resource; this version just needs to exist
      create = true
    }
  ]
}
```

---

### Flexible environment with container image

```hcl
module "app_engine" {
  source     = "../../modules/compute/gcp_app_engine"
  project_id = "my-project"

  application = { location_id = "us-east1" }

  services = [
    {
      key      = "worker-flex"
      service  = "worker"
      runtime  = "custom"
      env_type = "flexible"

      deployment_type            = "container"
      deployment_container_image = "us-docker.pkg.dev/my-project/my-repo/worker:latest"

      resources_cpu       = 2
      resources_memory_gb = 2.0
      resources_disk_gb   = 20

      liveness_check_path  = "/health"
      readiness_check_path = "/ready"

      scaling_type           = "automatic"
      min_instances          = 1
      max_instances          = 10
      target_cpu_utilization = 0.7
    }
  ]
}
```

---

### Application with IAP, firewall rules, and custom domain

```hcl
module "app_engine" {
  source     = "../../modules/compute/gcp_app_engine"
  project_id = "my-project"

  application = {
    location_id              = "us-central"
    iap_enabled              = true
    iap_oauth2_client_id     = "123456789-abc.apps.googleusercontent.com"
    iap_oauth2_client_secret = var.iap_secret
  }

  services = [
    {
      key     = "admin-portal"
      service = "default"
      runtime = "go122"

      deployment_type           = "zip"
      deployment_zip_source_url = "https://storage.googleapis.com/my-bucket/admin.zip"
    }
  ]

  firewall_rules = [
    {
      key          = "allow-corp"
      priority     = 100
      action       = "ALLOW"
      source_range = "203.0.113.0/24"
      description  = "Allow corporate network"
    },
    {
      key          = "deny-all"
      priority     = 2147483646
      action       = "DENY"
      source_range = "*"
      description  = "Default deny"
    }
  ]

  domain_mappings = [
    {
      key                 = "admin-domain"
      domain_name         = "admin.example.com"
      ssl_management_type = "AUTOMATIC"
    }
  ]
}
```

---

## Related Docs

- [App Engine Explainer](gcp-app-engine.md)
- [App Engine Deployment Plan](../../tf-plans/gcp_app_engine/README.md)
- [App Engine Documentation](https://cloud.google.com/appengine/docs)
- [Standard Runtimes](https://cloud.google.com/appengine/docs/standard/runtimes)
- [Flexible Environment](https://cloud.google.com/appengine/docs/flexible)
- [Traffic Splitting](https://cloud.google.com/appengine/docs/standard/splitting-traffic)
- [App Engine Pricing](https://cloud.google.com/appengine/pricing)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
