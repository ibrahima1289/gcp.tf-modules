># GCP Cloud Router Terraform Module

Reusable Terraform module for creating one or many [Google Cloud Routers](https://cloud.google.com/network-connectivity/docs/router) with optional BGP interfaces and peers for hybrid and dynamic routing deployments.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "cloud_router"
├── google_compute_router.router          (one per routers[] entry)
├── google_compute_router_interface.interface   (optional, per interface in routers[].interfaces)
└── google_compute_router_peer.peer             (optional, per peer in routers[].peers)
```

Flow:

```text
Input defaults (project_id, region, tags)
            ↓
Resolved routers map (per-item overrides)
            ↓
Router creation with labels + BGP config
            ↓
Optional interface creation (flattened map)
            ↓
Optional BGP peer creation (flattened map, depends on interfaces)
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
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Cloud Router with BGP config and optional labels |
| [`google_compute_router_interface`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) | Router interface bound to VPN tunnel, Interconnect, or subnetwork |
| [`google_compute_router_peer`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) | BGP peer for dynamic route exchange |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default project ID used by router entries that do not override `project_id`. |
| `routers` | `list(object)` | One or many router definitions. See [routers object fields](#routers-object-fields). |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default region used by router entries that do not override `region`. |
| `tags` | `map(string)` | `{}` | Common governance tags merged with `managed_by` and `created_date`. Applied as labels on router resources. |

---

## `routers` Object Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable unique key for `for_each`. |
| `name` | `string` | ✅ | — | Cloud Router name. |
| `network` | `string` | ✅ | — | VPC network self-link or name for the router. |
| `asn` | `number` | ✅ | — | BGP ASN for this router. |
| `project_id` | `string` | | `""` | Per-item project override. Resolves to module-level `project_id` if empty. |
| `region` | `string` | | `""` | Per-item region override. Resolves to module-level `region` if empty. |
| `description` | `string` | | `""` | Optional router description text. |
| `keepalive_interval` | `number` | | `20` | BGP keepalive interval in seconds. |
| `advertise_mode` | `string` | | `"DEFAULT"` | `DEFAULT` or `CUSTOM` route advertisement mode. |
| `advertised_groups` | `list(string)` | | `[]` | Route groups to advertise in `CUSTOM` mode (e.g., `ALL_SUBNETS`). |
| `advertised_ip_ranges` | `list(object)` | | `[]` | Custom IP ranges to advertise in `CUSTOM` mode. See fields below. |
| `encrypted_interconnect_router` | `bool` | | `false` | Enable for encrypted Interconnect MACSEC deployments. |
| `interfaces` | `list(object)` | | `[]` | Optional router interfaces. See [interfaces fields](#interfaces-fields). |
| `peers` | `list(object)` | | `[]` | Optional BGP peer configurations. See [peers fields](#peers-fields). |

### `advertised_ip_ranges` Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `range` | `string` | ✅ | — | CIDR range to advertise. |
| `description` | `string` | | `""` | Optional range description. |

---

## `interfaces` Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `name` | `string` | ✅ | — | Interface name, unique within the router. |
| `ip_range` | `string` | | `""` | Link-local IP range (e.g., `169.254.0.1/30`). |
| `ip_version` | `string` | | `"IPV4"` | `IPV4` or `IPV6`. |
| `vpn_tunnel` | `string` | | `""` | VPN tunnel self-link. Set for VPN-backed interfaces. |
| `interconnect_attachment` | `string` | | `""` | Interconnect VLAN attachment self-link. Set for Interconnect-backed interfaces. |
| `subnetwork` | `string` | | `""` | Subnetwork self-link. Set for Router Appliance deployments. |
| `redundant_interface` | `string` | | `""` | Name of an interface to form a redundant pair with. |

---

## `peers` Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `name` | `string` | ✅ | — | BGP peer name, unique within the router. |
| `interface` | `string` | ✅ | — | Name of the router interface this peer attaches to. |
| `peer_asn` | `number` | ✅ | — | Remote BGP AS number. |
| `peer_ip_address` | `string` | | `""` | Link-local IP of the remote BGP peer. |
| `ip_address` | `string` | | `""` | Link-local IP of this router side of the session. |
| `advertised_route_priority` | `number` | | `100` | Route priority (MED) advertised to peer. Lower is preferred. |
| `enable` | `bool` | | `true` | Enable or disable this BGP session. |
| `advertise_mode` | `string` | | `"DEFAULT"` | `DEFAULT` or `CUSTOM` route advertisement mode. |
| `advertised_groups` | `list(string)` | | `[]` | Route groups to advertise in `CUSTOM` mode. |
| `advertised_ip_ranges` | `list(object)` | | `[]` | Custom IP ranges to advertise in `CUSTOM` mode. |
| `bfd` | `list(object)` | | `[]` | Optional BFD configuration. Use a single-element list to enable. See [bfd fields](#bfd-fields). |

### `bfd` Fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `session_initialization_mode` | `string` | | `"DISABLED"` | `ACTIVE`, `PASSIVE`, or `DISABLED`. |
| `min_transmit_interval` | `number` | | `1000` | Minimum BFD transmit interval in milliseconds. |
| `min_receive_interval` | `number` | | `1000` | Minimum BFD receive interval in milliseconds. |
| `multiplier` | `number` | | `5` | BFD detection time multiplier. |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `router_ids` | `map(string)` | Router resource IDs keyed by router key. |
| `router_names` | `map(string)` | Router names keyed by router key. |
| `router_self_links` | `map(string)` | Router self-links keyed by router key. |
| `router_regions` | `map(string)` | Resolved regions per router key. |
| `router_projects` | `map(string)` | Resolved project IDs per router key. |
| `interface_ids` | `map(string)` | Interface IDs keyed by `<router_key>/<interface_name>`. |
| `peer_ids` | `map(string)` | BGP peer IDs keyed by `<router_key>/<peer_name>`. |
| `common_tags` | `map(string)` | Governance labels metadata produced in `locals.tf`. |

---

## Usage Example

```hcl
module "cloud_router" {
  source = "../../modules/networking/gcp_cloud_router"

  project_id = "my-platform-project"
  region     = "us-central1"

  tags = {
    owner       = "network-team"
    environment = "shared"
  }

  routers = [
    {
      key     = "vpn-router-central"
      name    = "vpn-router-central"
      network = "projects/my-platform-project/global/networks/platform-shared-vpc"
      asn     = 65001

      interfaces = [
        {
          name       = "if-vpn-central-1"
          ip_range   = "169.254.0.1/30"
          vpn_tunnel = "projects/my-platform-project/regions/us-central1/vpnTunnels/vpn-tunnel-01"
        }
      ]

      peers = [
        {
          name            = "peer-onprem-1"
          interface       = "if-vpn-central-1"
          peer_asn        = 65002
          peer_ip_address = "169.254.0.2"
          ip_address      = "169.254.0.1"
          bfd = [
            {
              session_initialization_mode = "ACTIVE"
            }
          ]
        }
      ]
    },
    {
      key            = "custom-advert-router"
      name           = "custom-advert-router"
      network        = "projects/my-platform-project/global/networks/platform-shared-vpc"
      asn            = 65003
      advertise_mode = "CUSTOM"
      advertised_groups = ["ALL_SUBNETS"]
      advertised_ip_ranges = [
        {
          range       = "192.168.100.0/24"
          description = "On-premises management range"
        }
      ]
    }
  ]
}
```

---

## Validation Behavior

- Unique `key` and `name` values are enforced across all routers.
- `advertise_mode` must be `DEFAULT` or `CUSTOM` (router-level and peer-level).
- `interfaces[*].ip_version` must be `IPV4` or `IPV6`.
- `peers[*].bfd[*].session_initialization_mode` must be `ACTIVE`, `PASSIVE`, or `DISABLED`.

---

## Related Docs

- [Cloud Router Overview](https://cloud.google.com/network-connectivity/docs/router)
- [Cloud Router Deployment Plan](../../../tf-plans/gcp_cloud_router/README.md)
- [Cloud NAT Module](../gcp_cloud_nat/README.md)
- [GCP Networks (VPC) Module](../gcp_networks/README.md)
- [GCP Subnetworks Module](../gcp_subnetworks/README.md)
