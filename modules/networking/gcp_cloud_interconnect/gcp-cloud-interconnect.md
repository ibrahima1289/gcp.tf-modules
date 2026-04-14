# Google Cloud Interconnect

## Service overview

[Google Cloud Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect) provides high-bandwidth, private, low-latency connectivity between your on-premises network and Google Cloud VPC networks. Unlike Cloud VPN (which routes traffic over the public internet in encrypted tunnels), Interconnect provides a direct physical or provider-facilitated connection to Google's network — no public internet traversal.

Interconnect is the right choice when you need consistent, high-throughput, low-latency private connectivity at enterprise scale.

---

## How Cloud Interconnect works

```text
On-premises Network (data center)
  └── Redundant circuits (cross-connects at a colocation facility)
        |
Google's Edge Network (at the colocation facility / PoP)
        |
VLAN Attachment (logical channel over the circuit, per VPC)
        |
Cloud Router (BGP session, dynamic route exchange)
        |
VPC Network (private route reachability)
```

---

## Interconnect types

| Type | Description | Who operates the circuit | Capacity options |
|------|-------------|-------------------------|-----------------|
| **Dedicated Interconnect** | Your equipment at a Google-supported colocation facility; you own the physical cross-connect | You | 10 Gbps or 100 Gbps per circuit |
| **Partner Interconnect** | A service provider operates the circuit between your facility and Google | Your network provider | 50 Mbps – 50 Gbps (provider-dependent) |

---

## Dedicated Interconnect capacity

| Circuits | Total capacity | Notes |
|:--------:|:-------------:|-------|
| 1 | 10 Gbps | No redundancy |
| 2 | 20 Gbps | Redundant (recommended minimum) |
| 4 | 40 Gbps | Enhanced redundancy (MACsec-capable) |
| 8 | 80 Gbps | High-capacity HA deployment |
| Up to 8 × 100G | 800 Gbps | Maximum per metro area |

---

## Partner Interconnect service levels

| Service level | Redundancy | SLA |
|--------------|:----------:|-----|
| **Layer 2** | Requires 2 VLAN attachments on 2 partner edge devices | 99.99% (if configured correctly) |
| **Layer 3** | Provider manages BGP and routing | Up to 99.9% |

---

## VLAN attachments

| Parameter | Description |
|-----------|-------------|
| **VLAN ID** | 802.1Q VLAN tag on the circuit |
| **Bandwidth** | Allocation from the physical circuit (e.g., 1, 2, 5, 10 Gbps) |
| **Cloud Router** | Each VLAN attachment connects to a Cloud Router for BGP session |
| **Encryption (MACsec)** | Optional layer-2 encryption on Dedicated Interconnect (100G circuits) |

---

## SLA tiers (Dedicated Interconnect)

| Configuration | SLA |
|--------------|-----|
| Single circuit, single VLAN | No SLA |
| Redundant circuits, same metro | 99.9% |
| Redundant circuits, different metros | 99.99% |

---

## When to use Cloud Interconnect

- Bandwidth and latency requirements exceed what Cloud VPN can provide.
- Enterprise workloads require predictable, consistent private connectivity.
- Large-scale data transfer (replication, migration) to/from Google Cloud.
- Hybrid architecture needs long-term dedicated transport (SAP, ERP, databases).
- Compliance requires traffic to never traverse the public internet.

---

## Core capabilities

- Dedicated and Partner Interconnect models for different deployment patterns.
- High-throughput, low-latency private data paths (no public internet).
- BGP dynamic routing with Cloud Router integration.
- MACsec encryption on Dedicated Interconnect (100G) for in-transit security.
- VLAN attachments per VPC for multi-network separation on a single circuit.

---

## Real-world usage

- Primary data-center to cloud transport for hybrid enterprise architectures.
- Mission-critical hybrid application connectivity (ERP, Oracle, SAP).
- Large-scale data migration from on-premises data centers to GCS and BigQuery.
- Cloud backup targets for on-premises databases over private high-bandwidth links.
- Disaster recovery with active replication across a dedicated private circuit.

---

## Security and operations guidance

- Deploy redundant circuits in separate facilities for 99.99% SLA.
- Restrict VLAN attachment management with least-privilege IAM roles (`roles/compute.networkAdmin`).
- Enable MACsec on 100G Dedicated Interconnect circuits for data-in-transit encryption.
- Use separate Cloud Routers for each VLAN attachment to isolate routing domains.
- Monitor circuit utilization and error counts with Cloud Monitoring metrics.
- Coordinate ASN and route policy governance to prevent BGP route leaks.
- Test failover behavior regularly by disabling one circuit and validating rerouting.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_interconnect_attachment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_interconnect_attachment) | Creates a VLAN attachment on a Dedicated or Partner Interconnect circuit |
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Cloud Router hosting the BGP session for the attachment |
| [`google_compute_router_interface`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) | Interface on Cloud Router linked to the VLAN attachment |
| [`google_compute_router_peer`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) | BGP peer for route exchange over the attachment |

---

## Related Docs

- [Cloud Interconnect Overview](https://cloud.google.com/network-connectivity/docs/interconnect)
- [Dedicated vs Partner Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/overview#choosing-interconnect)
- [Interconnect Redundancy](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/redundancy)
- [Cloud Router (BGP for Interconnect)](../gcp_cloud_router/gcp-cloud-router.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
