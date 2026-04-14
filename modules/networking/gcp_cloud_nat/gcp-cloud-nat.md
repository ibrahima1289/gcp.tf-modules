# Google Cloud NAT

## Service overview

[Google Cloud NAT](https://cloud.google.com/nat/docs) is a managed network address translation service that enables private Compute Engine VMs and GKE nodes to initiate outbound connections to the internet or other external destinations — without assigning public IP addresses to those resources. Cloud NAT is fully distributed (no single gateway appliance) and scales automatically with traffic.

Cloud NAT is a key component of secure network design: it allows private compute to fetch packages, pull container images, and call external APIs while keeping inbound exposure completely blocked.

---

## How Cloud NAT works

```text
Private VM (no external IP)
  └── Outbound TCP/UDP request to the internet
        |
Cloud Router (control plane, holds NAT configuration)
  └── Cloud NAT (data plane, distributed at Google edge)
        ├── Allocates source IP from NAT IP pool
        ├── Translates source address (SNAT)
        └── Returns response to the VM
              |
Internet / External endpoint
```

Cloud NAT is configured on a **Cloud Router** per region per VPC network. Traffic is translated at Google's distributed edge, not through a VM-based NAT gateway.

---

## NAT IP allocation modes

| Mode | Description | Best for |
|------|-------------|----------|
| **AUTO_ONLY** | Google automatically allocates NAT external IPs | Simple deployments; no control over outbound IP |
| **MANUAL_ONLY** | You reserve static external IPs and assign them to Cloud NAT | Workloads requiring allowlisting on external services |

---

## Subnet NAT configuration options

| Subnetwork source | Description |
|-------------------|-------------|
| `ALL_SUBNETWORKS_ALL_IP_RANGES` | NAT applies to all subnets in the region |
| `ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES` | All subnets, primary ranges only |
| `LIST_OF_SUBNETWORKS` | Explicit list of subnets and IP ranges |

---

## Port allocation modes

| Mode | Description |
|------|-------------|
| **Static port allocation** | Fixed number of NAT ports per VM (default 64 per endpoint) |
| **Dynamic port allocation** | Ports allocated on demand per connection; supports more concurrent connections per IP |

---

## Logging options

| Log filter | Description |
|------------|-------------|
| `ERRORS_ONLY` | Log only translation errors |
| `TRANSLATIONS_ONLY` | Log all successful translations |
| `ALL` | Log both errors and translations |

> Cloud NAT logs go to Cloud Logging. Enable only on debug/security-sensitive environments due to log volume.

---

## When to use Cloud NAT

- Workloads must remain private (no external IP) but need outbound internet connectivity.
- Security policy requires no public IP assignment on VMs or GKE nodes.
- Egress paths require centralized visibility and logging.
- GKE private clusters need to pull container images from public registries.

---

## Core capabilities

- Managed SNAT with no gateway appliance to operate or scale.
- Works with Cloud Router for configuration and routing control.
- Supports automatic and manual IP address allocation.
- Configurable per-subnet and per-IP-range NAT scope.
- Dynamic port allocation for high-connection-count workloads.
- Preserves inbound exposure controls (no inbound NAT — only outbound).

---

## Real-world usage

- Private GKE nodes pulling container images from Artifact Registry or Docker Hub.
- Private VM patching: apt/yum package updates from external repositories.
- Controlled egress in regulated environments requiring defined outbound IPs.
- Cloud Run (VPC egress) and other serverless services using private networking.
- Private Dataflow, Dataproc, and Batch workers needing internet egress.

---

## Security and operations guidance

- Use `LIST_OF_SUBNETWORKS` to explicitly scope which subnets get NAT; avoid over-provisioning.
- Apply egress firewall rules to control which destinations private VMs can reach.
- Use `MANUAL_ONLY` IP allocation when external partners or APIs require known outbound IPs.
- Enable NAT logging (`ERRORS_ONLY`) in production; use `ALL` temporarily for troubleshooting.
- Size for peak simultaneous connections: each NAT IP supports ~64K ports per destination endpoint.
- Monitor `nat/dropped_sent_packets_count` metric to detect port exhaustion.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_router_nat`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | Creates the Cloud NAT configuration on a Cloud Router |
| [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | Cloud Router that hosts the NAT configuration |
| [`google_compute_address`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | Reserves static external IPs for MANUAL_ONLY allocation |

---

## Related Docs

- [Cloud NAT Overview](https://cloud.google.com/nat/docs)
- [Cloud NAT Terraform Module README](README.md)
- [Cloud NAT Deployment Plan README](../../../tf-plans/gcp_cloud_nat/README.md)
- [Cloud Router (required dependency)](../gcp_cloud_router/gcp-cloud-router.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
