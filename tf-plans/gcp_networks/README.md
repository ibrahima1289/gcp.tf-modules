# GCP VPC Deployment Plan

Deployment wrapper for the [GCP VPC Network module](../../modules/networking/gcp_vpc/README.md). Creates one or many Google Cloud VPC networks in a single `terraform apply`, with a consistent label strategy and optional Shared VPC host registration.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_vpc/
└── module "vpc"  →  modules/networking/gcp_vpc/
    ├── google_compute_network          "platform-shared-vpc"   (routing_mode = GLOBAL, shared_vpc_host)
    ├── google_compute_network          "apps-dev-vpc"          (routing_mode = REGIONAL)
    ├── ...
    └── google_compute_shared_vpc_host_project  (per unique project where shared_vpc_host = true)
```

**Label merge order applied at the module level:**

```
var.labels  →  created_date / managed_by (from locals)  →  networks[*].labels
```

---

## Prerequisites

- Terraform `>= 1.5` installed
- `gcloud` authenticated (`gcloud auth application-default login`)
- GCP project with the Compute Engine API enabled (`compute.googleapis.com`)
- IAM: `roles/compute.networkAdmin` (or `roles/editor`) on the target project(s)
- For Shared VPC: `roles/compute.xpnAdmin` at the org or folder level

---

## Quick Start

```bash
cd tf-plans/gcp_vpc

# 1. Edit terraform.tfvars with your project_id and network definitions.

# 2. Initialise the workspace.
terraform init

# 3. Validate configuration.
terraform validate

# 4. Preview changes.
terraform plan

# 5. Apply.
terraform apply
```

---

## Files

| File | Purpose |
|------|---------|
| [main.tf](main.tf) | Calls the `modules/networking/gcp_vpc` module with all inputs |
| [variables.tf](variables.tf) | Wrapper input variable declarations |
| [locals.tf](locals.tf) | `created_date` timestamp for labels |
| [outputs.tf](outputs.tf) | Pass-through of all module outputs |
| [providers.tf](providers.tf) | Google provider and optional GCS remote backend |
| [terraform.tfvars](terraform.tfvars) | Example input values |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default GCP project ID. Can be overridden per network. |
| `networks` | `list(object)` | One or more VPC networks to create. See [networks object fields](#networks-object-fields). |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default region for the Google provider. VPC networks are global. |
| `labels` | `map(string)` | `{}` | Common labels merged into every network resource. |

---

## `networks` Object Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable `for_each` key. Must be unique across the list. |
| `name` | `string` | ✅ | — | VPC network name. 2–63 chars, lowercase, hyphens allowed. |
| `description` | `string` | | `""` | Human-readable description. |
| `project_id` | `string` | | `""` | Per-network project override. Falls back to `var.project_id`. |
| `auto_create_subnetworks` | `bool` | | `false` | `false` = custom mode (recommended). `true` = auto mode. |
| `routing_mode` | `string` | | `"REGIONAL"` | `REGIONAL` or `GLOBAL`. |
| `mtu` | `number` | | `1460` | MTU in bytes. Valid range: 1300–8896. |
| `delete_default_routes_on_create` | `bool` | | `false` | Remove the default `0.0.0.0/0` route on network creation. |
| `network_firewall_policy_enforcement_order` | `string` | | `"AFTER_CLASSIC_FIREWALL"` | `AFTER_CLASSIC_FIREWALL` or `BEFORE_CLASSIC_FIREWALL`. |
| `enable_ula_internal_ipv6` | `bool` | | `false` | Enable internal IPv6 ULA range. |
| `internal_ipv6_range` | `string` | | `""` | `/48` ULA range. Auto-assigned when left empty. |
| `shared_vpc_host` | `bool` | | `false` | Register the network's project as a Shared VPC host. |
| `labels` | `map(string)` | | `{}` | Per-network labels, merged on top of common labels. |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `network_ids` | `map(string)` | Network resource IDs keyed by network key. |
| `network_names` | `map(string)` | Network names keyed by network key. |
| `network_self_links` | `map(string)` | Network self-links (URI). Used to attach subnets and other resources. |
| `network_gateway_ipv4` | `map(string)` | Default gateway IPv4 addresses keyed by network key. |
| `network_projects` | `map(string)` | Resolved project IDs keyed by network key. |
| `common_labels` | `map(string)` | Common labels applied to all networks. |

---

## Remote State (Optional)

Uncomment the `backend "gcs"` block in [providers.tf](providers.tf) and set real values:

```hcl
backend "gcs" {
  bucket = "my-terraform-state-bucket"
  prefix = "gcp-vpc"
}
```

Create the bucket once:

```bash
gcloud storage buckets create gs://my-terraform-state-bucket \
  --project=my-project-id \
  --location=us-central1 \
  --uniform-bucket-level-access
```

---

## Related Docs

- [GCP VPC Network Module](../../modules/networking/gcp_vpc/README.md)
- [GCP Subnet Deployment Plan](../gcp_subnet/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Terraform Deployment Guide (CLI + GitHub Actions)](../../gcp-terraform-deployment-cli-github-actions.md)
- [Google Cloud VPC Overview](https://cloud.google.com/vpc/docs/vpc)
- [Shared VPC Overview](https://cloud.google.com/vpc/docs/shared-vpc)
