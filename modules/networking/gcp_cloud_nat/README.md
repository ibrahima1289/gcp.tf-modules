# GCP Cloud NAT Terraform Module

Reusable Terraform module for creating one or many [Google Cloud NAT](https://cloud.google.com/nat/docs) configurations, with optional Cloud Router creation per NAT definition.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "cloud_nat"
├── google_compute_router.router                 (optional, per NAT with create_router=true)
├── google_compute_router_nat.nat_standard       (dynamic port allocation disabled)
└── google_compute_router_nat.nat_dynamic        (dynamic port allocation enabled)
```

Flow:

```text
Input defaults (project_id, region, tags)
            ↓
Resolved NAT map (per-item overrides)
            ↓
Optional router creation
            ↓
Cloud NAT creation (standard or dynamic)
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
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Optional router creation when `create_router = true` |
| [`google_compute_router_nat`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | Cloud NAT configuration |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default project ID used by NAT entries that do not override `project_id`. |
| `nats` | `list(object)` | One or many NAT definitions. See [nats object fields](#nats-object-fields). |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default region used by NAT entries that do not override `region`. |
| `tags` | `map(string)` | `{}` | Common governance tags merged with `managed_by` and `created_date`. |

---

## `nats` Object Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable unique key for `for_each`. |
| `name` | `string` | ✅ | — | Cloud NAT name. |
| `project_id` | `string` | | `""` | Per-item project override. |
| `region` | `string` | | `""` | Per-item region override. |
| `create_router` | `bool` | | `false` | Create a router in-module for this NAT. |
| `router` | `string` | | `""` | Existing router name when `create_router = false`. |
| `router_name` | `string` | | `""` | Router name when creating router; defaults to `${name}-router`. |
| `router_description` | `string` | | `""` | Optional router description text. |
| `network` | `string` | | `""` | Required when `create_router = true`. |
| `router_asn` | `number` | | `64514` | BGP ASN for created router. |
| `router_keepalive_interval` | `number` | | `20` | BGP keepalive interval seconds. |
| `nat_ip_allocate_option` | `string` | | `"AUTO_ONLY"` | `AUTO_ONLY` or `MANUAL_ONLY`. |
| `nat_ips` | `list(string)` | | `[]` | Static IP self-links when `MANUAL_ONLY`. |
| `drain_nat_ips` | `list(string)` | | `[]` | NAT IPs to drain gracefully. |
| `source_subnetwork_ip_ranges_to_nat` | `string` | | `"ALL_SUBNETWORKS_ALL_IP_RANGES"` | NAT scope selection mode. |
| `subnetworks` | `list(object)` | | `[]` | Per-subnetwork NAT mappings when scope is `LIST_OF_SUBNETWORKS`. |
| `enable_endpoint_independent_mapping` | `bool` | | `true` | Endpoint-independent mapping behavior. |
| `enable_dynamic_port_allocation` | `bool` | | `false` | Enables dynamic port allocation mode. |
| `min_ports_per_vm` | `number` | | `64` | Minimum NAT ports per VM. |
| `max_ports_per_vm` | `number` | | `4096` | Maximum NAT ports per VM (dynamic mode). |
| `udp_idle_timeout_sec` | `number` | | `30` | UDP idle timeout seconds. |
| `icmp_idle_timeout_sec` | `number` | | `30` | ICMP idle timeout seconds. |
| `tcp_established_idle_timeout_sec` | `number` | | `1200` | TCP established timeout seconds. |
| `tcp_transitory_idle_timeout_sec` | `number` | | `30` | TCP transitory timeout seconds. |
| `tcp_time_wait_timeout_sec` | `number` | | `120` | TCP time-wait timeout seconds. |
| `log_config_enable` | `bool` | | `false` | Enable NAT logging block. |
| `log_config_filter` | `string` | | `"ERRORS_ONLY"` | `ERRORS_ONLY`, `TRANSLATIONS_ONLY`, or `ALL`. |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `nat_ids` | `map(string)` | NAT resource IDs keyed by NAT key. |
| `nat_names` | `map(string)` | NAT names keyed by NAT key. |
| `nat_router_names` | `map(string)` | Effective router names used by each NAT key. |
| `created_router_names` | `map(string)` | Routers created by this module call. |
| `nat_regions` | `map(string)` | Resolved regions per NAT key. |
| `nat_projects` | `map(string)` | Resolved project IDs per NAT key. |
| `common_tags` | `map(string)` | Governance tags metadata produced in `locals.tf`. |

---

## Usage Example

```hcl
module "cloud_nat" {
  source = "../../modules/networking/gcp_cloud_nat"

  project_id = "my-platform-project"
  region     = "us-central1"

  tags = {
    owner       = "platform-team"
    environment = "shared"
  }

  nats = [
    {
      key           = "prod-nat-auto"
      name          = "prod-nat-auto"
      create_router = true
      network       = "projects/my-platform-project/global/networks/platform-shared-vpc"
      router_name   = "prod-nat-router"

      nat_ip_allocate_option = "AUTO_ONLY"
      source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

      log_config_enable = true
      log_config_filter = "ERRORS_ONLY"
    },
    {
      key    = "prod-nat-manual"
      name   = "prod-nat-manual"
      router = "existing-router-central"

      nat_ip_allocate_option = "MANUAL_ONLY"
      nat_ips = [
        "projects/my-platform-project/regions/us-central1/addresses/nat-ip-01"
      ]

      source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
      subnetworks = [
        {
          name                     = "projects/my-platform-project/regions/us-central1/subnetworks/apps-central"
          source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE"]
          secondary_ip_range_names = []
        }
      ]
    }
  ]
}
```

---

## Validation Behavior

- Unique `key` and `name` values are enforced.
- `nat_ip_allocate_option` must be `AUTO_ONLY` or `MANUAL_ONLY`.
- `MANUAL_ONLY` requires at least one `nat_ips` entry.
- `LIST_OF_SUBNETWORKS` requires at least one `subnetworks` entry.
- `create_router = true` requires `network`.
- `create_router = false` requires `router`.

---

## Related Docs

- [Cloud NAT Overview](https://cloud.google.com/nat/docs/overview)
- [Cloud Router Overview](https://cloud.google.com/network-connectivity/docs/router)
- [Cloud NAT Deployment Plan](../../../tf-plans/gcp_cloud_nat/README.md)
- [Cloud Router Module](../gcp_cloud_router/README.md)
- [GCP Networks (VPC) Module](../gcp_networks/README.md)
- [GCP Subnetworks Module](../gcp_subnetworks/README.md)
