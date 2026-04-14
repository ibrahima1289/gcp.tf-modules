# GCP Subnet — Terraform Deployment Plan

This deployment plan (`tf-plans/gcp_subnet`) is a ready-to-use wrapper that calls the reusable [Subnet module](../../modules/networking/gcp_subnet/README.md) to create and manage one or many Google Cloud VPC subnets.

---

## Architecture

```text
tf-plans/gcp_subnet
        │
        └─► modules/networking/gcp_subnet
                    │
                    └─ google_compute_subnetwork (for_each)
                       ├─ primary CIDR
                       ├─ secondary IP ranges
                       ├─ private Google access
                       └─ optional VPC Flow Logs
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.5 |
| Google Provider | >= 6.0 |
| Caller permissions | Network Admin / appropriate project IAM |
| Authentication | Application Default Credentials or Workload Identity Federation |
| Existing network | VPC network name or self link available before apply |

---

## Quick Start

```bash
# 1) Authenticate
gcloud auth application-default login --no-launch-browser

# 2) Initialize
terraform init

# 3) Validate
terraform validate

# 4) Plan
terraform plan -var-file="terraform.tfvars"

# 5) Apply
terraform apply -var-file="terraform.tfvars"
```

---

## Files

| File | Purpose |
|---|---|
| `main.tf` | Calls the subnet module with wrapper inputs |
| `locals.tf` | Generates `created_date` metadata |
| `variables.tf` | Wrapper input variables |
| `outputs.tf` | Pass-through outputs from module |
| `providers.tf` | Terraform and provider constraints |
| `terraform.tfvars` | Example values for subnet deployment |

---

## Variables

### Required

| Variable | Type | Description |
|---|---|---|
| `subnets` | `list(object)` | List of subnet definitions to create |
| `project_id` or per-subnet `project_id` | `string` | Default project or per-subnet project override |
| `network` or per-subnet `network` | `string` | Default VPC network or per-subnet network override |

### Optional

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-central1` | Default subnet region |
| `labels` | `map(string)` | `{}` | Common labels/tags merged with metadata |

---

## Outputs

| Output | Description |
|---|---|
| `subnet_self_links` | Subnet self links keyed by subnet key |
| `subnet_names` | Subnet names keyed by subnet key |
| `subnet_regions` | Effective regions keyed by subnet key |
| `subnet_cidr_ranges` | Primary CIDR blocks keyed by subnet key |
| `subnet_gateway_addresses` | Gateway addresses keyed by subnet key |
| `subnet_private_google_access` | Private Google access status keyed by subnet key |
| `common_labels` | Common metadata labels map |

---

## Related Docs

- [Subnetworks Module README](../../modules/networking/gcp_subnetworks/README.md)
- [Cloud NAT Deployment Plan](../gcp_cloud_nat/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Terraform Deployment Guide (CLI & GitHub Actions)](../../gcp-terraform-deployment-cli-github-actions.md)
