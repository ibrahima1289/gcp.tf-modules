# Google Cloud Router

## Service overview

[Google Cloud Router](https://cloud.google.com/network-connectivity/docs/router) is a managed BGP (Border Gateway Protocol) routing service for Google Cloud VPC networks. It enables dynamic route exchange between your VPC and external networks connected via Cloud VPN or Cloud Interconnect. Cloud Router automatically propagates learned routes into your VPC's routing table — eliminating the need to manually manage static routes when the external topology changes.

Cloud Router is a required component for HA VPN tunnels, Interconnect VLAN attachments, and Network Connectivity Center spokes.

---

## How Cloud Router works

```text
External Network (on-premises / another cloud)
  └── VPN Tunnel or Interconnect VLAN attachment
        |
Cloud Router (per region, per VPC)
  ├── Interface (linked to VPN tunnel or Interconnect attachment)
  └── BGP Peer (external ASN, BGP session IP)
        ├── Receives routes from external: 192.168.1.0/24 → VPN tunnel
        └── Advertises routes to external: 10.0.0.0/8 (VPC ranges)
              |
VPC Routing Table (dynamic routes auto-injected)
```

---

## Router components

| Component | Description |
|-----------|-------------|
| **Router** | Regional resource; belongs to one VPC network; holds all interfaces and peers |
| **Interface** | Logical link on the router connected to a VPN tunnel or Interconnect VLAN attachment |
| **BGP peer** | External BGP neighbor the router exchanges routes with over the interface |
| **ASN** | Autonomous System Number for the Cloud Router (Google-managed range or custom) |

---

## Interface types

| Interface attachment | Description |
|---------------------|-------------|
| **HA VPN tunnel** | Interface linked to a Cloud VPN tunnel (`vpn_tunnel` parameter) |
| **Dedicated Interconnect VLAN** | Interface linked to a VLAN attachment (`interconnect_attachment` parameter) |
| **Partner Interconnect VLAN** | Interface linked to a Partner VLAN attachment |
| **NCC Router Appliance** | Interface linked to a Network Connectivity Center router appliance VM |
| **No attachment (IP-only)** | Interface with `ip_range` only; used for NCC spoke routing |

---

## BGP advertisement modes

| Mode | Description |
|------|-------------|
| `DEFAULT` | Advertises all VPC subnet ranges in the router's region |
| `CUSTOM` | Advertises only explicitly specified routes (`advertised_ip_ranges`) and optionally `ALL_SUBNETS` or `ALL_VPC_SUBNETS` |

---

## BFD (Bidirectional Forwarding Detection)

BFD provides sub-second failure detection on BGP peer links — much faster than BGP keepalive timers alone.

| BFD parameter | Description |
|---------------|-------------|
| **Session mode** | `ACTIVE` (Cloud Router initiates), `PASSIVE` (waits for peer), `DISABLED` |
| **Min transmit interval** | How often BFD packets are sent (ms) |
| **Min receive interval** | Minimum receive interval the router accepts from peer |
| **Multiplier** | Number of missed packets before the session is declared down |

---

## When to use Cloud Router

- Hybrid connectivity uses HA VPN or Interconnect and routes must update dynamically.
- Routes change frequently (new subnets, decommissioned prefixes) and manual static routes are impractical.
- You use Network Connectivity Center spokes with BGP route propagation.
- You need sub-second failover using BFD on BGP peer sessions.

---

## Core capabilities

- Dynamic BGP route advertisement and learning.
- Integration with Cloud VPN (HA), Interconnect (Dedicated and Partner), and NCC.
- Custom route advertisement for controlled prefix export.
- BFD support for fast failure detection.
- Regional deployment; one router can serve multiple VPN tunnels or Interconnect attachments.

---

## Real-world usage

- Enterprise data-center to cloud BGP route exchange via Dedicated Interconnect.
- HA VPN pairs with Cloud Router for automatic failover between tunnels.
- Multi-site connectivity via NCC with Cloud Router providing BGP to each spoke.
- Custom route advertisement to expose only specific subnets to on-premises networks.
- Dynamic failover: BFD detects link failure in <1 second and reroutes BGP traffic.

---

## Security and operations guidance

- Restrict BGP peer and router configuration to authorized network administrators.
- Standardize ASN strategy organization-wide; avoid overlapping ASNs across regions.
- Use `CUSTOM` advertisement mode to explicitly control which prefixes are exported.
- Validate route import/export policy to prevent route leaks between security domains.
- Deploy redundant Cloud Routers (via HA VPN or redundant Interconnect) for resilience.
- Monitor BGP session status (`router/bgp/sent_routes_count`, `received_routes_count`) in Cloud Monitoring.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Creates the Cloud Router with ASN and BGP settings |
| [`google_compute_router_interface`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) | Adds an interface linked to a VPN tunnel or Interconnect attachment |
| [`google_compute_router_peer`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) | Adds a BGP peer to an interface |
| [`google_compute_router_nat`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | Adds a Cloud NAT configuration to the router |

---

## Related Docs

- [Cloud Router Overview](https://cloud.google.com/network-connectivity/docs/router)
- [Cloud Router Terraform Module README](README.md)
- [Cloud Router Deployment Plan README](../../../tf-plans/gcp_cloud_router/README.md)
- [Cloud NAT (uses Cloud Router)](../gcp_cloud_nat/gcp-cloud-nat.md)
- [Cloud VPN (uses Cloud Router)](../gcp_cloud_vpn/gcp-cloud-vpn.md)
- [Cloud Interconnect (uses Cloud Router)](../gcp_cloud_interconnect/gcp-cloud-interconnect.md)
- [Network Connectivity Center (uses Cloud Router)](../gcp_network_connectivity_center/gcp-network-connectivity-center.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
