# GCP Cloud Router Deployment Plan

Ready-to-use Terraform wrapper for deploying one or many Cloud Routers using the reusable module at [modules/networking/gcp_cloud_router](../../modules/networking/gcp_cloud_router/README.md).

> Part of [gcp.tf-modules](../../README.md)

---

## Architecture

```text
tf-plans/gcp_cloud_router/
└── module "cloud_router"  →  modules/networking/gcp_cloud_router/
    ├── google_compute_router.router
    ├── google_compute_router_interface.interface    (optional)
    └── google_compute_router_peer.peer              (optional)
```

---

## Prerequisites

- Terraform `>= 1.5`
- Google provider `>= 6.0`
- Authenticated `gcloud` / Application Default Credentials
- Required APIs: `compute.googleapis.com`
- IAM permissions for router and BGP peer management in target projects

---

## Files

| File | Purpose |
|------|---------|
| [main.tf](main.tf) | Calls the reusable Cloud Router module |
| [variables.tf](variables.tf) | Wrapper input variables |
| [locals.tf](locals.tf) | `created_date` metadata for governance tags |
| [outputs.tf](outputs.tf) | Pass-through outputs from the module |
| [providers.tf](providers.tf) | Provider and optional backend configuration |
| [terraform.tfvars](terraform.tfvars) | Example values: VPN router with interfaces/peers and a custom-advertisement router |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default project ID for router definitions. |
| `routers` | `list(object)` | One or many router definitions. |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default region for router definitions. |
| `tags` | `map(string)` | `{}` | Common governance tags merged with `created_date` and `managed_by`. |

---

## Quick Start

```bash
cd tf-plans/gcp_cloud_router
terraform init
terraform validate
terraform plan
terraform apply
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `router_ids` | Router IDs keyed by router key |
| `router_names` | Router names keyed by router key |
| `router_self_links` | Router self-links keyed by router key |
| `router_regions` | Resolved regions per router key |
| `router_projects` | Resolved project IDs per router key |
| `interface_ids` | Interface IDs keyed by `<router_key>/<interface_name>` |
| `peer_ids` | BGP peer IDs keyed by `<router_key>/<peer_name>` |
| `common_tags` | Governance tags metadata returned by the module |

---

## Related Docs

- [Cloud Router Module README](../../modules/networking/gcp_cloud_router/README.md)
- [Cloud Router Overview](https://cloud.google.com/network-connectivity/docs/router)
- [Cloud NAT Deployment Plan](../gcp_cloud_nat/README.md)
- [GCP Networks (VPC) Deployment Plan](../gcp_networks/README.md)
- [GCP Subnetworks Deployment Plan](../gcp_subnetworks/README.md)
