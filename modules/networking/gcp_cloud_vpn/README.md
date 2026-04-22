# GCP Cloud VPN Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for deploying [Google Cloud HA VPN](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview) gateways with encrypted IPsec tunnels, external peer gateways, and BGP sessions via Cloud Router. Supports multiple gateway pairs, on-premises and cross-cloud peers, and optional BFD for sub-second failover.

---

## Architecture

```text
GCP Project
└── VPC Network
    │
    ├── HA VPN Gateway  (google_compute_ha_vpn_gateway)
    │   ├── Interface 0  ──── Tunnel 0 ────────────────► Peer Interface 0
    │   │   └── IPsec / IKEv2 encrypted                  (on-premises / AWS / Azure)
    │   └── Interface 1  ──── Tunnel 1 ────────────────► Peer Interface 1
    │                                                    (google_compute_external_vpn_gateway)
    │
    ├── External Peer Gateway  (google_compute_external_vpn_gateway)
    │   ├── Interface 0 — Public IP of remote device
    │   └── Interface 1 — Public IP of remote device (TWO_IPS_REDUNDANCY)
    │
    └── Cloud Router  (pre-existing, referenced by name)
        ├── Router Interface 0  (google_compute_router_interface)
        │   └── BGP Peer 0      (google_compute_router_peer)
        │       └── ASN + peer IP exchanged over Tunnel 0
        └── Router Interface 1  (google_compute_router_interface)
            └── BGP Peer 1      (google_compute_router_peer)
                └── ASN + peer IP exchanged over Tunnel 1

  99.99% SLA requires:
    ✅  Two tunnels (one per gateway interface)
    ✅  BGP dynamic routing (Cloud Router)
    ✅  Two distinct peer IPs on the remote device
```

---

## Resources Created

| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| HA VPN Gateway | `google_compute_ha_vpn_gateway` | Active/active gateway with 2 external IPs |
| External Peer Gateway | `google_compute_external_vpn_gateway` | Represents the remote VPN endpoint |
| VPN Tunnel | `google_compute_vpn_tunnel` | Encrypted IPsec / IKEv2 tunnel |
| Router Interface | `google_compute_router_interface` | Local BGP endpoint on the Cloud Router |
| BGP Peer | `google_compute_router_peer` | BGP session to the remote peer ASN |

> **Cloud Router is not created by this module.** Use the [GCP Cloud Router module](../gcp_cloud_router/README.md) to create the router before deploying VPN tunnels.

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5 |
| hashicorp/google | >= 6.0 |

---

## Variables

### Top-Level

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project_id` | `string` | ✅ | — | Default GCP project ID |
| `region` | `string` | | `"us-central1"` | Default region |
| `tags` | `map(string)` | | `{}` | Governance labels |

### `vpn_gateways` — List of HA VPN Gateway Objects

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this gateway entry |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `name` | `string` | ✅ | — | Gateway resource name |
| `network` | `string` | ✅ | — | VPC network self-link or name |
| `project_id` | `string` | | `""` | Per-gateway project override |
| `region` | `string` | | `""` | Per-gateway region override |
| `stack_type` | `string` | | `"IPV4_ONLY"` | `IPV4_ONLY` \| `IPV4_IPV6` |
| `peer_gateway_key` | `string` | | `""` | Key referencing a `peer_gateways` entry |
| `interconnect_attachments` | `list(object)` | | `[]` | VLAN attachment IDs for HA VPN over Interconnect |
| `tunnels[*].key` | `string` | ✅ | — | Unique key within this gateway |
| `tunnels[*].name` | `string` | ✅ | — | Tunnel resource name |
| `tunnels[*].vpn_gateway_interface` | `number` | ✅ | — | `0` or `1` — local gateway interface |
| `tunnels[*].peer_external_gateway_interface` | `number` | | `0` | Peer interface index |
| `tunnels[*].shared_secret` | `string` | ✅ | — | IKE pre-shared key |
| `tunnels[*].ike_version` | `number` | | `2` | IKE version (`2` recommended) |
| `tunnels[*].router` | `string` | ✅ | — | Existing Cloud Router name |
| `tunnels[*].router_interface_name` | `string` | ✅ | — | Name for the Cloud Router interface |
| `tunnels[*].router_bgp_ip_range` | `string` | ✅ | — | Local BGP IP CIDR (e.g. `"169.254.1.1/30"`) |
| `tunnels[*].bgp_peer_name` | `string` | ✅ | — | Name for the BGP peer resource |
| `tunnels[*].bgp_peer_ip` | `string` | ✅ | — | Remote BGP peer IP (e.g. `"169.254.1.2"`) |
| `tunnels[*].bgp_peer_asn` | `number` | ✅ | — | Remote AS number |
| `tunnels[*].advertised_route_priority` | `number` | | `100` | Lower = preferred during failover |
| `tunnels[*].bfd` | `object` | | `null` | BFD configuration for sub-second detection |
| `tunnels[*].advertised_ip_ranges` | `list(object)` | | `[]` | Custom route ranges to advertise |

### `peer_gateways` — List of External Peer Gateway Objects

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this peer entry |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `name` | `string` | ✅ | — | Peer gateway resource name |
| `description` | `string` | | `""` | Human-readable description |
| `project_id` | `string` | | `""` | Per-peer project override |
| `redundancy_type` | `string` | | `"TWO_IPS_REDUNDANCY"` | `SINGLE_IP_INTERNALLY_REDUNDANT` \| `TWO_IPS_REDUNDANCY` \| `FOUR_IPS_REDUNDANCY` |
| `interfaces[*].id` | `number` | ✅ | — | Interface index (0-based) |
| `interfaces[*].ip_address` | `string` | ✅ | — | Public IP of the remote device interface |

---

## Outputs

| Name | Description |
|------|-------------|
| `ha_gateway_ids` | HA VPN gateway IDs keyed by gateway key |
| `ha_gateway_names` | HA VPN gateway names keyed by gateway key |
| `ha_gateway_self_links` | HA VPN gateway self-links keyed by gateway key |
| `ha_gateway_vpn_interfaces` | Allocated external IPs per gateway (use to configure the peer device) |
| `peer_gateway_ids` | External peer gateway IDs keyed by peer key |
| `peer_gateway_self_links` | External peer gateway self-links keyed by peer key |
| `vpn_tunnel_ids` | Tunnel IDs keyed by `<gateway_key>/<tunnel_key>` |
| `vpn_tunnel_names` | Tunnel names keyed by `<gateway_key>/<tunnel_key>` |
| `vpn_tunnel_self_links` | Tunnel self-links keyed by `<gateway_key>/<tunnel_key>` |
| `router_interface_names` | Cloud Router interface names keyed by `<gateway_key>/<tunnel_key>` |
| `bgp_peer_names` | BGP peer names keyed by `<gateway_key>/<tunnel_key>` |
| `common_labels` | Governance labels generated by this module call |

---

## Usage

### HA VPN to on-premises (two tunnels, BGP)

```hcl
module "gcp_cloud_vpn" {
  source     = "../../modules/networking/gcp_cloud_vpn"
  project_id = "my-project"
  region     = "us-central1"

  peer_gateways = [
    {
      key             = "on-prem-fw"
      name            = "on-prem-firewall"
      description     = "Main datacenter Cisco ASA firewall"
      redundancy_type = "TWO_IPS_REDUNDANCY"
      interfaces = [
        { id = 0, ip_address = "203.0.113.1" },
        { id = 1, ip_address = "203.0.113.2" },
      ]
    }
  ]

  vpn_gateways = [
    {
      key              = "prod-vpn"
      name             = "prod-ha-vpn"
      network          = "projects/my-project/global/networks/prod-vpc"
      peer_gateway_key = "on-prem-fw"

      tunnels = [
        {
          key                           = "tunnel-0"
          name                          = "prod-vpn-tunnel-0"
          vpn_gateway_interface         = 0
          peer_external_gateway_interface = 0
          shared_secret                 = var.vpn_shared_secret_0
          router                        = "prod-cloud-router"
          router_interface_name         = "prod-vpn-if-0"
          router_bgp_ip_range           = "169.254.1.1/30"
          bgp_peer_name                 = "prod-vpn-peer-0"
          bgp_peer_ip                   = "169.254.1.2"
          bgp_peer_asn                  = 65001
        },
        {
          key                           = "tunnel-1"
          name                          = "prod-vpn-tunnel-1"
          vpn_gateway_interface         = 1
          peer_external_gateway_interface = 1
          shared_secret                 = var.vpn_shared_secret_1
          router                        = "prod-cloud-router"
          router_interface_name         = "prod-vpn-if-1"
          router_bgp_ip_range           = "169.254.2.1/30"
          bgp_peer_name                 = "prod-vpn-peer-1"
          bgp_peer_ip                   = "169.254.2.2"
          bgp_peer_asn                  = 65001
          advertised_route_priority     = 100
        },
      ]
    }
  ]

  tags = { environment = "production", team = "network" }
}

# After apply: use ha_gateway_vpn_interfaces output to configure the peer device
output "gcp_external_ips" {
  value = module.gcp_cloud_vpn.ha_gateway_vpn_interfaces
}
```

### Multiple gateway pairs

```hcl
module "gcp_cloud_vpn" {
  source     = "../../modules/networking/gcp_cloud_vpn"
  project_id = var.project_id

  peer_gateways = [
    {
      key             = "dc1-peer"
      name            = "dc1-vpn-peer"
      redundancy_type = "TWO_IPS_REDUNDANCY"
      interfaces = [
        { id = 0, ip_address = "198.51.100.1" },
        { id = 1, ip_address = "198.51.100.2" },
      ]
    },
    {
      key             = "aws-peer"
      name            = "aws-vgw-peer"
      redundancy_type = "FOUR_IPS_REDUNDANCY"
      interfaces = [
        { id = 0, ip_address = "54.10.0.1" },
        { id = 1, ip_address = "54.10.0.2" },
        { id = 2, ip_address = "54.10.0.3" },
        { id = 3, ip_address = "54.10.0.4" },
      ]
    },
  ]

  vpn_gateways = [
    {
      key              = "dc1-vpn"
      name             = "dc1-ha-vpn"
      network          = "projects/${var.project_id}/global/networks/prod-vpc"
      peer_gateway_key = "dc1-peer"
      tunnels          = [ /* ... tunnel objects ... */ ]
    },
    {
      key              = "aws-vpn"
      name             = "aws-ha-vpn"
      network          = "projects/${var.project_id}/global/networks/prod-vpc"
      peer_gateway_key = "aws-peer"
      tunnels          = [ /* ... tunnel objects ... */ ]
    },
  ]
}
```

---

## Link-Local IP Range Convention

Each BGP session uses a `/30` from the `169.254.0.0/16` link-local range. Assign non-overlapping `/30` blocks per tunnel:

| Tunnel | Local IP (GCP) | Peer IP (remote) | CIDR |
|--------|---------------|-----------------|------|
| Tunnel 0 | `169.254.1.1` | `169.254.1.2` | `/30` |
| Tunnel 1 | `169.254.2.1` | `169.254.2.2` | `/30` |
| Tunnel 2 | `169.254.3.1` | `169.254.3.2` | `/30` |

---

## Related Docs

- [Cloud VPN Explainer](gcp-cloud-vpn.md)
- [GCP Cloud Router Module](../gcp_cloud_router/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [HA VPN overview](https://cloud.google.com/network-connectivity/docs/vpn/concepts/ha-vpn)
- [HA VPN topologies](https://cloud.google.com/network-connectivity/docs/vpn/concepts/topologies)
- [google_compute_ha_vpn_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway)
- [google_compute_external_vpn_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_external_vpn_gateway)
- [google_compute_vpn_tunnel](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel)
