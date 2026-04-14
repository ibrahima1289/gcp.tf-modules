# Google Traffic Director

## Service overview

[Google Traffic Director](https://cloud.google.com/traffic-director/docs) is Google Cloud's fully managed traffic control plane for service networking. It implements the xDS (Envoy) API to push traffic management configuration to Envoy proxies and gRPC-native services — enabling advanced L7 traffic policies (routing, retries, timeouts, circuit breaking, traffic splitting) without modifying application code.

Traffic Director is the Google Cloud implementation of a service mesh control plane and works with both Envoy sidecar proxies (in GKE or VMs) and proxyless gRPC services.

---

## How Traffic Director works

```text
Traffic Director (control plane — Google-managed)
  └── Pushes xDS configuration (EDS, CDS, LDS, RDS)
        |
Envoy Proxy (data plane — runs as sidecar or standalone)
  ├── Service A (microservice)
  └── Service B (microservice)
        |
Advanced traffic policy:
  - Weighted routing (canary 5% → Service B v2)
  - Retry policy (3 retries on 5xx)
  - Circuit breaker (max pending requests)
  - Timeout (2s global deadline)
```

---

## Key traffic management features

| Feature | Description |
|---------|-------------|
| **Weighted traffic splitting** | Route X% to one backend, Y% to another (canary, blue/green) |
| **Path-based routing** | Route by URL path to different backend services |
| **Header-based routing** | Route by HTTP header values (A/B testing, feature flags) |
| **Fault injection** | Inject delays or errors for chaos/resilience testing |
| **Retry policy** | Automatic retry on configurable HTTP response codes |
| **Timeout policy** | Enforce per-route or per-service request deadlines |
| **Circuit breaker** | Limit pending connections or requests to protect backends |
| **Outlier detection** | Eject unhealthy backends from the load-balancing pool |
| **Load balancing algorithm** | Round-robin, least-request, ring hash, random |

---

## Traffic Director vs Cloud Load Balancing

| Dimension | Traffic Director | Cloud Load Balancing |
|-----------|-----------------|---------------------|
| **Architecture** | Service mesh / sidecar-based (Envoy xDS) | Managed Google infrastructure |
| **Protocol** | HTTP/1, HTTP/2, gRPC | HTTP/1, HTTP/2, gRPC, TCP, UDP |
| **Traffic visibility** | Per-service, per-request observability | Per-frontend/backend |
| **Advanced policies** | Circuit breaking, fault injection, outlier detection | Basic health check and failover |
| **Target workloads** | Microservices in GKE or VMs with Envoy | General workloads, external traffic |
| **Use case** | Internal service-to-service L7 governance | External or internal ingress |

---

## Deployment modes

| Mode | Description |
|------|-------------|
| **Envoy sidecar (GKE)** | Envoy runs as a sidecar container in each Pod; Traffic Director configures via xDS |
| **Envoy sidecar (VM)** | Envoy runs on each VM; configured via Traffic Director xDS |
| **Proxyless gRPC** | gRPC client libraries connect directly to Traffic Director xDS — no sidecar needed |
| **Managed sidecar injection** | ASM (Anthos Service Mesh) auto-injects and manages Envoy alongside Traffic Director |

---

## When to use Traffic Director

- You operate many distributed microservices and need centralized traffic governance.
- Progressive rollouts require weighted traffic shifting with fine-grained control.
- Service traffic policies need to be applied without modifying application code.
- You need circuit breaking, fault injection, or outlier detection for resilience testing.
- You run gRPC services and want proxyless, library-native service mesh.

---

## Core capabilities

- Centralized traffic-policy configuration and enforcement via xDS.
- Service mesh-compatible routing for Envoy sidecar and proxyless gRPC.
- Canary and weighted release with instant rollback.
- Circuit breaking, retry policies, and fault injection for resilience.
- Request-level observability and distributed tracing integration.

---

## Real-world usage

- Large API platform traffic governance across many internal microservices.
- Progressive delivery: 5% → 20% → 100% canary rollout with automatic rollback.
- Hybrid mesh routing between on-premises Envoy and GKE workloads.
- Chaos engineering: inject latency or error faults without application changes.
- gRPC service mesh with proxyless xDS (no sidecar overhead).

---

## Security and operations guidance

- Restrict traffic policy authoring to authorized teams via IAM.
- Define clear service ownership boundaries before applying policies.
- Use gradual rollout strategies (weighted splits) for all production changes.
- Track SLO metrics and configure rollback thresholds before each release.
- Enable Envoy access logging and tracing for request-level observability.
- Combine with Anthos Service Mesh (ASM) for mutual TLS between services.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_backend_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | Backend service with Traffic Director policies (load balancing, circuit breaking) |
| [`google_compute_url_map`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | Route configuration (path, header, weighted routing rules) |
| [`google_network_services_grpc_route`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_services_grpc_route) | gRPC service route for Traffic Director |
| [`google_network_services_http_route`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_services_http_route) | HTTP route for Traffic Director service mesh |
| [`google_network_services_mesh`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_services_mesh) | Traffic Director mesh resource grouping routes and gateways |

---

## Related Docs

- [Traffic Director Overview](https://cloud.google.com/traffic-director/docs)
- [xDS API and Envoy Integration](https://cloud.google.com/traffic-director/docs/proxyless-overview)
- [Traffic Director vs Cloud Load Balancing](https://cloud.google.com/traffic-director/docs/traffic-director-concepts)
- [Anthos Service Mesh](https://cloud.google.com/service-mesh/docs)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
