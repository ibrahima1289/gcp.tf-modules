# GCP VPC Network Terraform Module

Reusable Terraform module for creating one or many [Google Cloud VPC networks](https://cloud.google.com/vpc/docs/vpc) with a consistent, list-driven interface. Supports custom-mode networks, global or regional routing, internal IPv6, firewall policy enforcement order, Shared VPC host registration, and per-network label overrides.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "vpc"
├── google_compute_network.network          (for_each networks)
│   ├── Step 2 — Core identity (name, description, project)
│   ├── Step 3 — Network mode & routing (auto_create_subnetworks, routing_mode, mtu)
│   ├── Step 4 — Firewall policy enforcement order
│   ├── Step 5 — Internal IPv6 ULA (optional)
│   └── Step 6 — Labels (common + per-network merged)
└── google_compute_shared_vpc_host_project.host   (shared_vpc_host = true networks only)
    └── One resource per unique project_id that requests Shared VPC host
```

**Label merge order** (last wins):

```
var.labels  →  created_date / managed_by  →  networks[*].labels
```

---

## Requirements

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |

> **Note:** This module does not own a `provider "google"` block. The provider must be configured in the calling wrapper (see [tf-plans/gcp_vpc](../../../tf-plans/gcp_vpc/README.md)). This is required to allow `for_each` on the module call.

---

## Resources

| Resource | Purpose |
|----------|---------|
| [`google_compute_network`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | Creates each VPC network |
| [`google_compute_shared_vpc_host_project`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_shared_vpc_host_project) | Registers the project as a Shared VPC host (optional) |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default GCP project ID. Must be 6–30 chars, lowercase letters, digits, or hyphens. |
| `networks` | `list(object)` | List of VPC networks to create. See [`networks` object fields](#networks-object-fields) below. |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default region for the provider. VPC networks are global; this value is used for provider configuration and labels. |
| `labels` | `map(string)` | `{}` | Common labels merged into every network. |

---

## `networks` Object Fields

Each item in the `networks` list maps to one `google_compute_network` resource.

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable `for_each` key. Must be unique. |
| `name` | `string` | ✅ | — | VPC network name. 2–63 chars, lowercase letters, digits, or hyphens. |
| `description` | `string` | | `""` | Human-readable description of the network. |
| `project_id` | `string` | | `""` | Per-network project override. Falls back to module `project_id`. |
| `auto_create_subnetworks` | `bool` | | `false` | `false` = custom mode (recommended). `true` = auto mode (one subnet per region). |
| `routing_mode` | `string` | | `"REGIONAL"` | `REGIONAL` — routes traffic within the originating region. `GLOBAL` — routes across all regions. |
| `mtu` | `number` | | `1460` | Maximum Transmission Unit. Valid range: 1300–8896. Common values: `1460` (default), `1500` (VLAN attachment). |
| `delete_default_routes_on_create` | `bool` | | `false` | Remove the default `0.0.0.0/0` route when the network is created. |
| `network_firewall_policy_enforcement_order` | `string` | | `"AFTER_CLASSIC_FIREWALL"` | `AFTER_CLASSIC_FIREWALL` or `BEFORE_CLASSIC_FIREWALL`. Controls whether network firewall policies are evaluated before or after classic VPC firewall rules. |
| `enable_ula_internal_ipv6` | `bool` | | `false` | Enable internal IPv6 ULA range on the network. |
| `internal_ipv6_range` | `string` | | `""` | A `/48` ULA IPv6 range. Only used when `enable_ula_internal_ipv6 = true`. Auto-assigned when left empty. |
| `shared_vpc_host` | `bool` | | `false` | Register the network's project as a [Shared VPC host project](https://cloud.google.com/vpc/docs/shared-vpc). |
| `labels` | `map(string)` | | `{}` | Per-network labels merged on top of common labels. |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `network_ids` | `map(string)` | Network resource IDs keyed by network key. |
| `network_names` | `map(string)` | Network names keyed by network key. |
| `network_self_links` | `map(string)` | Network self-links keyed by network key. Used to attach subnets, VMs, and load balancers. |
| `network_gateway_ipv4` | `map(string)` | Default gateway IPv4 addresses keyed by network key. |
| `network_projects` | `map(string)` | Resolved project IDs keyed by network key. |
| `common_labels` | `map(string)` | Common labels applied to every network in this module call. |

---

## Usage Example

```hcl
module "vpc" {
  source = "../../modules/networking/gcp_vpc"

  project_id = "my-platform-project"
  region     = "us-central1"

  labels = {
    owner       = "platform-team"
    environment = "shared"
    created_date = "2026-04-11"
  }

  networks = [
    {
      key          = "platform-shared"
      name         = "platform-shared-vpc"
      description  = "Shared VPC host network for platform services"
      routing_mode = "GLOBAL"
      shared_vpc_host = true
      labels = {
        tier = "platform"
      }
    },
    {
      key          = "apps-dev"
      name         = "apps-dev-vpc"
      description  = "Development network for application teams"
      routing_mode = "REGIONAL"
      mtu          = 1460
      labels = {
        tier        = "dev"
        cost_center = "engineering"
      }
    },
    {
      key                      = "apps-prod"
      name                     = "apps-prod-vpc"
      description              = "Production network with internal IPv6 and custom firewall policy order"
      routing_mode             = "REGIONAL"
      enable_ula_internal_ipv6 = true
      network_firewall_policy_enforcement_order = "BEFORE_CLASSIC_FIREWALL"
      labels = {
        tier = "prod"
      }
    }
  ]
}
```

Consume outputs in downstream modules (e.g., subnet module):

```hcl
module "subnets" {
  source = "../../modules/networking/gcp_subnet"

  project_id = "my-platform-project"
  region     = "us-central1"
  network    = module.vpc.network_self_links["platform-shared"]

  subnets = [
    {
      key        = "apps-central"
      name       = "apps-central"
      cidr_range = "10.10.0.0/24"
    }
  ]
}
```

---

## Validation Behaviour

| Rule | Checked at |
|------|-----------|
| `project_id` format (6–30 chars, lowercase, hyphens) | `terraform validate` |
| `networks[*].key` uniqueness | `terraform validate` |
| `networks[*].name` uniqueness | `terraform validate` |
| `networks[*].name` format (2–63 chars, lowercase, hyphens) | `terraform validate` |
| `routing_mode` ∈ `{REGIONAL, GLOBAL}` | `terraform validate` |
| `network_firewall_policy_enforcement_order` enum | `terraform validate` |
| `mtu` ∈ 1300–8896 | `terraform validate` |

---

## Design Notes

- **Custom mode by default.** `auto_create_subnetworks = false` creates a custom-mode VPC, which gives full control over subnet placement and CIDR ranges. This is the recommended approach for production environments.
- **No provider block.** The module declares only `required_providers`, never a `provider "google"` block. This allows the caller to use `for_each` on the module.
- **`delete_default_routes_on_create`.** Setting this to `true` removes the implicit `0.0.0.0/0` default route. Use this when you need full control over routing, e.g., for environments where all egress flows through a hub or firewall appliance.
- **Shared VPC deduplication.** `google_compute_shared_vpc_host_project` is a project-level resource. The module creates at most one per unique project, even if multiple networks in that project have `shared_vpc_host = true`.
- **Internal IPv6.** `internal_ipv6_range` is only passed to the resource when both `enable_ula_internal_ipv6 = true` and a range string is provided; otherwise it is `null` and Google assigns the range automatically.

---

## Related Docs

- [GCP VPC Deployment Plan](../../../tf-plans/gcp_vpc/README.md)
- [GCP Subnet Module](../gcp_subnet/README.md) — create subnets inside VPC networks
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud VPC Overview](https://cloud.google.com/vpc/docs/vpc)
- [google_compute_network (Terraform Registry)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network)
- [Shared VPC Overview](https://cloud.google.com/vpc/docs/shared-vpc)
