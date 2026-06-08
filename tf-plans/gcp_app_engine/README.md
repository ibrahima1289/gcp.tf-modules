# GCP App Engine Deployment Plan

Wrapper configuration for the [GCP App Engine module](../../modules/compute/gcp_app_engine/README.md). Deploys an App Engine application with one or many service versions across standard and flexible environments, with optional traffic splits, firewall rules, and custom domain mappings.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_app_engine/
├── providers.tf       → Terraform requirements, GCS backend (optional), google provider
├── variables.tf       → project_id, region, tags, application, services[], firewall_rules[], ...
├── locals.tf          → created_date
├── main.tf            → module "gcp_app_engine" wrapper call
├── outputs.tf         → pass-through outputs from module
├── terraform.tfvars   → example multi-service configuration
└── README.md          → this file
        ↓
modules/compute/gcp_app_engine/
├── google_app_engine_application           (singleton)
├── google_app_engine_standard_app_version  (for_each service key)
├── google_app_engine_flexible_app_version  (for_each service key)
├── google_app_engine_service_split_traffic (optional canary/blue-green)
├── google_app_engine_firewall_rule         (for_each rule key)
└── google_app_engine_domain_mapping        (for_each mapping key)
```

---

## Prerequisites

- GCP project with [App Engine API](https://console.cloud.google.com/apis/library/appengine.googleapis.com) enabled (`appengine.googleapis.com`)
- Terraform `>= 1.5` and Google provider `>= 6.0`
- Authenticated Application Default Credentials (`gcloud auth application-default login`)
- IAM role: `roles/appengine.appAdmin` on the target project
- Deployment artifacts (ZIP or container image) must exist before `terraform apply`

> ⚠️ **App Engine location is permanent.** Once `application.location_id` is set, it cannot be changed without deleting and recreating the entire application (which also deletes all services and versions).

---

## Apply Workflow

```bash
# 1. Authenticate
gcloud auth application-default login --no-launch-browser

# 2. Enable App Engine API
gcloud services enable appengine.googleapis.com --project=my-project-id

# 3. Upload deployment ZIP to GCS (if using zip deployment_type)
gsutil cp ./dist/app.zip gs://my-project-deploy/app.zip

# 4. Update terraform.tfvars with your application and service configuration

# 5. Initialise
terraform init

# 6. Review plan
terraform plan -out=tfplan

# 7. Apply
terraform apply tfplan

# 8. Retrieve application URL
terraform output application_url

# 9. Retrieve DNS records for custom domain (if configured)
terraform output domain_mapping_resource_records
```

> **Canary deployments**: Update `traffic_allocations` in `terraform.tfvars` and re-apply to gradually shift traffic between versions without redeploying code.

---

## Variables

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | GCP project ID |
| `application` | `object` | App Engine application configuration |

### Optional

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Interface consistency; location set via `application.location_id` |
| `tags` | `map(string)` | `{}` | Common governance labels |
| `services` | `list(object)` | `[]` | One or many service versions (standard or flexible) |
| `firewall_rules` | `list(object)` | `[]` | App Engine firewall rules |
| `domain_mappings` | `list(object)` | `[]` | Custom domain mappings |
| `dispatch_rules` | `list(object)` | `[]` | URL dispatch rules |

For the full nested `services[]` schema see the [module variable reference](../../modules/compute/gcp_app_engine/README.md#variables).

---

## Example Configurations

### Minimal standard Python app

```hcl
application = { location_id = "us-central" }

services = [
  {
    key                       = "web"
    service                   = "default"
    runtime                   = "python312"
    deployment_type           = "zip"
    deployment_zip_source_url = "https://storage.googleapis.com/my-bucket/app.zip"
  }
]
```

### Traffic split for canary deploy

```hcl
services = [
  {
    key                       = "api-v1"
    service                   = "api"
    runtime                   = "nodejs20"
    version_id                = "v1"
    deployment_type           = "zip"
    deployment_zip_source_url = "https://storage.googleapis.com/bucket/api-v1.zip"
    traffic_split_enabled     = true
    traffic_split_shard_by    = "COOKIE"
    traffic_allocations       = { "v1" = "0.9", "v2" = "0.1" }
  },
  {
    key                       = "api-v2"
    service                   = "api"
    runtime                   = "nodejs20"
    version_id                = "v2"
    deployment_type           = "zip"
    deployment_zip_source_url = "https://storage.googleapis.com/bucket/api-v2.zip"
  }
]
```

### Flexible container worker

```hcl
services = [
  {
    key                        = "worker"
    service                    = "worker"
    runtime                    = "custom"
    env_type                   = "flexible"
    deployment_type            = "container"
    deployment_container_image = "us-docker.pkg.dev/my-project/repo/worker:latest"
    resources_cpu              = 2
    resources_memory_gb        = 2.0
    liveness_check_path        = "/health"
    readiness_check_path       = "/ready"
    scaling_type               = "automatic"
    min_instances              = 1
    max_instances              = 10
  }
]
```

### Skip a service without removing from config

```hcl
services = [
  { key = "old-service", service = "legacy", runtime = "php83",
    deployment_type = "zip", deployment_zip_source_url = "gs://b/x.zip",
    create = false }
]
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `application_id` | Application ID (matches project ID) |
| `application_url` | Default `https://{project}.appspot.com` URL |
| `default_hostname` | Default hostname |
| `default_bucket` | Default GCS staging bucket |
| `standard_version_ids` | Standard version IDs keyed by service key |
| `standard_version_names` | Fully-qualified standard version names |
| `flexible_version_ids` | Flexible version IDs keyed by service key |
| `flexible_version_names` | Fully-qualified flexible version names |
| `split_traffic_ids` | Traffic split resource IDs |
| `firewall_rule_ids` | Firewall rule IDs keyed by rule key |
| `domain_mapping_ids` | Domain mapping IDs keyed by mapping key |
| `domain_mapping_resource_records` | DNS records for custom domains |
| `common_tags` | Governance tags used in this run |

---

## Related Docs

- [GCP App Engine Module](../../modules/compute/gcp_app_engine/README.md)
- [App Engine Explainer](../../modules/compute/gcp_app_engine/gcp-app-engine.md)
- [App Engine Documentation](https://cloud.google.com/appengine/docs)
- [Standard vs Flexible Environments](https://cloud.google.com/appengine/docs/the-appengine-environments)
- [Traffic Splitting](https://cloud.google.com/appengine/docs/standard/splitting-traffic)
- [App Engine Pricing](https://cloud.google.com/appengine/pricing)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
