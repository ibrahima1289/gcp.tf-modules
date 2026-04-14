# Google Cloud VPN

## Service overview

[Google Cloud VPN](https://cloud.google.com/network-connectivity/docs/vpn) creates encrypted IPsec tunnels between your on-premises network (or another cloud) and Google Cloud VPC networks. All traffic through Cloud VPN tunnels is encrypted in transit using IKEv2.

Cloud VPN is the most common way to establish hybrid connectivity when Dedicated Interconnect is not yet available, not cost-justified, or when you need an encrypted backup path alongside Interconnect.

---

## How Cloud VPN works

```text
On-premises Network (or other cloud)
  └── VPN Gateway (on-premises device)
        |
Encrypted IPsec tunnel (IKEv2, AES-256)
        |
Cloud VPN Gateway (Google-managed, per region)
  └── VPN Tunnel (one per gateway pair direction)
        |
Cloud Router (BGP session over tunnel — HA VPN)
  └── VPC Network
        └── Workloads (VMs, GKE, etc.)
```

---

## VPN types

| Type | Description | Tunnels | SLA | Routing |
|------|-------------|:-------:|-----|---------|
| **Classic VPN** | Single external IP gateway; one tunnel direction | 1 per gateway | No SLA | Static routes or BGP via Cloud Router |
| **HA VPN** | Two external IP pairs; 99.99% SLA; active/active tunnel pairs | 2 per gateway pair | **99.99%** | BGP via Cloud Router (required) |

> HA VPN is strongly recommended for all production deployments. Classic VPN does not provide an SLA and is not suited for HA architectures.

---

## HA VPN gateway configurations

| Configuration | Description |
|--------------|-------------|
| **Two Cloud VPN gateways** (Google ↔ Google) | Both sides are GCP; fully automated interface negotiation |
| **Cloud VPN ↔ on-premises peer** | One GCP gateway, one on-prem device (Cisco, Palo Alto, Juniper, etc.) |
| **Cloud VPN ↔ AWS VGW** | Cross-cloud connectivity to AWS Virtual Private Gateway |
| **Cloud VPN ↔ Azure VPN Gateway** | Cross-cloud connectivity to Azure |

---

## Routing modes

| Mode | Description | Use case |
|------|-------------|----------|
| **Static routing** | Routes manually configured; no BGP required | Simple Classic VPN setups, fixed topology |
| **Policy-based routing** | Traffic selectors define which IPs to forward | Legacy VPN devices; limited to Classic VPN |
| **Dynamic routing (BGP)** | Routes exchanged via BGP through Cloud Router | HA VPN; adapts automatically to topology changes |

---

## Tunnel specifications

| Parameter | Value |
|-----------|-------|
| **Encryption** | IKEv2, AES-128/256, SHA-1/256 |
| **Max bandwidth per tunnel** | ~3 Gbps (aggregate; multiple tunnels for higher throughput) |
| **MTU** | 1460 bytes (default; can be adjusted) |
| **Dead peer detection (DPD)** | Supported |
| **NAT traversal (NAT-T)** | Supported |
| **IKE lifetime** | Configurable |

---

## When to use Cloud VPN

- You need secure site-to-site encrypted connectivity to Google Cloud.
- Interconnect is unavailable, cost-prohibitive, or not yet provisioned.
- Hybrid migration requires rapid private connectivity setup.
- You need an encrypted backup path alongside Dedicated Interconnect.
- Cross-cloud (AWS/Azure) connectivity is required via encrypted tunnels.

---

## Core capabilities

- HA VPN for redundant tunnel pairs with 99.99% availability SLA.
- Encrypted IKEv2 IPsec transport for all hybrid traffic.
- Integration with Cloud Router for dynamic BGP route exchange.
- Multiple tunnels per gateway for aggregated bandwidth.
- Cross-cloud and cross-VPN-gateway connectivity patterns.

---

## Real-world usage

- Branch office to cloud secure connectivity for internal applications.
- Hybrid migration transition architecture: on-premises + cloud during cutover.
- Encrypted backup path for enterprises with Dedicated Interconnect.
- Cross-cloud connectivity to AWS or Azure workloads.
- Dev/test environments connecting to corporate network services.

---

## Security and operations guidance

- Use HA VPN (not Classic VPN) for all production environments.
- Use strong IKE ciphers (AES-256, SHA-256) and rotate pre-shared keys regularly.
- Deploy redundant tunnels across different on-premises edge devices.
- Monitor tunnel health with Cloud Monitoring `vpn_tunnel_established` metric.
- Use BGP dynamic routing (Cloud Router) to automatically adapt routes during failover.
- Validate route policy behavior and AS path filtering after any topology changes.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_ha_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway) | Creates an HA VPN gateway with two external IP interfaces |
| [`google_compute_vpn_tunnel`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel) | Creates an IPsec tunnel between two gateways |
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Cloud Router that manages BGP sessions for the tunnel |
| [`google_compute_router_interface`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) | Interface on Cloud Router linked to the VPN tunnel |
| [`google_compute_router_peer`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) | BGP peer configuration for route exchange |
| [`google_compute_external_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_external_vpn_gateway) | Represents the on-premises or external VPN peer |

---

## Related Docs

- [Cloud VPN Overview](https://cloud.google.com/network-connectivity/docs/vpn)
- [HA VPN Overview](https://cloud.google.com/network-connectivity/docs/vpn/concepts/ha-vpn-overview)
- [Classic VPN vs HA VPN](https://cloud.google.com/network-connectivity/docs/vpn/concepts/choosing-networks-routing)
- [Cloud Router (BGP for VPN)](../gcp_cloud_router/gcp-cloud-router.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
