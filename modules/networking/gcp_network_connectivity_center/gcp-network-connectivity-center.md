# Google Network Connectivity Center

## Service overview

[Google Network Connectivity Center (NCC)](https://cloud.google.com/network-connectivity/docs/network-connectivity-center) is a hub-and-spoke network topology management platform for hybrid and multi-cloud connectivity. NCC centralizes routing policy and simplifies site-to-site reachability by allowing spokes (network connections) to be attached to a central hub — and optionally enabling full mesh routing between all spokes through that hub.

Without NCC, connecting many sites requires complex point-to-point VPN or Interconnect meshes. NCC replaces this with a single managed hub.

---

## How Network Connectivity Center works

```text
NCC Hub (central routing domain in a GCP project)
  ├── Spoke: VPN tunnel (Branch Office A → Cloud VPN)
  ├── Spoke: VPN tunnel (Branch Office B → Cloud VPN)
  ├── Spoke: Interconnect VLAN (Data Center → Dedicated Interconnect)
  ├── Spoke: Router Appliance (SD-WAN virtual appliance VM)
  └── Spoke: VPC (another GCP VPC network)
        |
Full-mesh routing between spokes (if enabled)
  └── Branch A ↔ Branch B (via NCC hub, without direct tunnel)
        └── Data Center ↔ Branch A (via NCC hub)
```

---

## Hub modes

| Mode | Description | Use case |
|------|-------------|----------|
| **VPC network** | Hub represents a VPC; spokes connect external sites to it | Standard hybrid hub-and-spoke |
| **Hybrid connectivity** | Spokes carry traffic between external sites via the hub | Multi-site full-mesh without direct links |

---

## Spoke types

| Spoke type | Description | Underlying technology |
|------------|-------------|-----------------------|
| **HA VPN spoke** | HA VPN tunnel attached to the hub | Cloud VPN (HA) |
| **Dedicated Interconnect spoke** | VLAN attachment on Dedicated Interconnect | Cloud Interconnect |
| **Partner Interconnect spoke** | VLAN attachment on Partner Interconnect | Cloud Interconnect (Partner) |
| **Router Appliance spoke** | A VM running a third-party SD-WAN or routing appliance | Compute Engine VM with BGP |
| **VPC spoke** | Connects another GCP VPC to the hub | VPC Peering alternative with centralized policy |

---

## Route exchange model

| Behavior | Description |
|---------|-------------|
| **Hub-to-spoke** | Hub advertises routes to all attached spokes |
| **Spoke-to-hub** | Each spoke advertises its local routes to the hub |
| **Spoke-to-spoke** | With data transfer enabled, spokes can route to each other via the hub |
| **BGP propagation** | Cloud Router on each spoke exchanges routes with NCC via BGP |

> Spoke-to-spoke data transfer incurs an additional per-GB charge.

---

## Routing domains

Spokes can be assigned to **routing domains** to control which spokes exchange routes with each other. This allows you to isolate traffic (e.g., prod spokes don't exchange routes with dev spokes) within a single hub.

---

## When to use Network Connectivity Center

- You manage many branch sites, data centers, or cloud VPCs that need mutual reachability.
- Network topology requires centralized routing policy management.
- Hybrid connectivity spans multiple providers or transport types (VPN + Interconnect + SD-WAN).
- You want to replace a complex point-to-point VPN mesh with a hub-and-spoke model.

---

## Core capabilities

- Hub-and-spoke model for centralized connectivity management.
- Supports VPN, Interconnect, Router Appliance, and VPC spokes.
- Full-mesh spoke-to-spoke routing through the hub (data transfer enabled).
- Routing domains for isolation within a hub.
- Cloud Router BGP integration for dynamic route propagation.

---

## Real-world usage

- Enterprise branch office network consolidation (dozens of sites via NCC hub).
- Multi-cloud connectivity: GCP + on-premises + Azure/AWS via Router Appliance SD-WAN.
- Hybrid architecture requiring uniform reachability across sites without complex VPN meshes.
- SD-WAN integration: third-party appliances (Cisco, Aruba, Palo Alto) as Router Appliance spokes.

---

## Security and operations guidance

- Restrict hub and spoke attachment management with IAM (`roles/networkconnectivity.hubAdmin`).
- Validate route propagation scope to avoid unintended reachability across domains.
- Use routing domains to segregate production, staging, and development connectivity.
- Monitor spoke health and BGP session status centrally via Cloud Monitoring.
- Review BGP route policies on each spoke's Cloud Router to prevent route leaks.
- Enable VPC Flow Logs on hub VPC for centralized traffic visibility.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_network_connectivity_hub`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_hub) | Creates the NCC hub in a central project |
| [`google_network_connectivity_spoke`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_spoke) | Attaches a VPN, Interconnect, Router Appliance, or VPC spoke to the hub |
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Cloud Router that provides BGP to the spoke |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `networkconnectivity.googleapis.com` API |

---

## Related Docs

- [Network Connectivity Center Overview](https://cloud.google.com/network-connectivity/docs/network-connectivity-center)
- [NCC Hub and Spoke Concepts](https://cloud.google.com/network-connectivity/docs/network-connectivity-center/concepts/overview)
- [Router Appliance Overview](https://cloud.google.com/network-connectivity/docs/router-appliance/overview)
- [Cloud Router (BGP for NCC spokes)](../gcp_cloud_router/gcp-cloud-router.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
