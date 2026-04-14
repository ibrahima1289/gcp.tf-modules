# Google Cloud Load Balancing

## Service overview

[Google Cloud Load Balancing](https://cloud.google.com/load-balancing/docs) is a fully distributed, software-defined load balancing platform. It distributes traffic across backends (VMs, instance groups, NEGs, GKE pods) to improve availability, performance, and scale. Cloud Load Balancing is not based on a single appliance — traffic is processed at Google's edge PoPs globally, providing instant failover and zero warm-up time.

---

## How Cloud Load Balancing works

```text
Client
  └── Frontend (forwarding rule + IP + port)
        ├── Target proxy (HTTP, HTTPS, TCP, SSL, gRPC)
        │     └── URL map (path/host-based routing — HTTP(S) only)
        └── Backend service or backend bucket
              ├── Instance group (MIG, unmanaged)
              ├── Network Endpoint Group (NEG) — Cloud Run, GKE, serverless
              └── Health check (per backend)
```

---

## Load balancer types

| Type | Scope | Traffic | Protocol | Use case |
|------|-------|---------|----------|----------|
| **Global External Application (HTTP(S))** | Global | External | HTTP, HTTPS, gRPC | Public web apps, CDN, API gateways |
| **Regional External Application** | Regional | External | HTTP, HTTPS | Regional external web apps |
| **Global External Proxy Network (SSL)** | Global | External | SSL/TLS (TCP) | Non-HTTP TLS apps requiring global routing |
| **Global External Proxy Network (TCP)** | Global | External | TCP | Non-HTTP global TCP services |
| **Regional External Passthrough (Network)** | Regional | External | TCP, UDP | Game servers, UDP apps, non-proxied TCP |
| **Regional Internal Application** | Regional | Internal | HTTP, HTTPS, gRPC | Internal microservices, private APIs |
| **Regional Internal Passthrough (Network)** | Regional | Internal | TCP, UDP | Internal TCP/UDP services, hybrid NLB |
| **Cross-region Internal Application** | Global | Internal | HTTP, HTTPS | Internal global traffic across regions |

> **Application LB** = Layer 7 (URL routing, headers, gRPC). **Proxy Network LB** = Layer 4 with TLS termination. **Passthrough Network LB** = Layer 4, client IP preserved.

---

## Key features by load balancer family

| Feature | Application LB (L7) | Passthrough LB (L4) |
|---------|--------------------|--------------------|
| **URL path routing** | ✅ | ❌ |
| **Host header routing** | ✅ | ❌ |
| **gRPC support** | ✅ | ❌ |
| **WebSocket support** | ✅ | ✅ |
| **Client IP preservation** | Via `X-Forwarded-For` | ✅ (direct) |
| **SSL termination** | ✅ | Proxy LB only |
| **Cloud CDN integration** | ✅ | ❌ |
| **Cloud Armor integration** | ✅ | Limited |
| **Backend: Cloud Run / GKE pods** | ✅ (NEG) | ❌ |

---

## Backend types

| Backend | Description |
|---------|-------------|
| **Managed Instance Group (MIG)** | Group of VMs; supports autoscaling |
| **Unmanaged Instance Group** | Static group of VMs |
| **Zonal NEG (GKE)** | Route directly to GKE pods (container-native LB) |
| **Serverless NEG** | Route to Cloud Run, App Engine, or Cloud Functions |
| **Internet NEG** | Route to external backends (hybrid/multi-cloud) |
| **Private Service Connect NEG** | Route to PSC-exposed services |
| **Backend bucket** | Serve static content from GCS |

---

## When to use Cloud Load Balancing

- You run multiple backend instances and need even traffic distribution.
- Traffic requires global or regional routing to the nearest healthy backend.
- High availability and automatic failover are mandatory.
- You need path/host-based routing (Application LB).
- You need to protect backends from DDoS with Cloud Armor.

---

## Core capabilities

- Global and regional load balancing modes.
- Internal and external traffic entry points with shared architecture.
- HTTP(S), TCP, UDP, gRPC, and SSL protocol support.
- Health checks with configurable check intervals and thresholds.
- Weighted traffic splitting for canary deployments.
- Autoscaling backends with Managed Instance Groups.

---

## Real-world usage

- Public web application front door with global anycast routing.
- Internal REST and gRPC API service mesh traffic distribution.
- GKE pod-level container-native load balancing via NEGs.
- Hybrid load balancing with on-premises or multi-cloud backends via Internet NEGs.
- Blue/green and canary deployments using traffic weight splits.

---

## Security and operations guidance

- Enforce managed TLS certificates (Google-managed) on all HTTPS frontends.
- Attach Cloud Armor security policies to external Application LBs for WAF and DDoS protection.
- Define health checks with appropriate thresholds for each backend service.
- Separate internet-facing and internal-only traffic into different load balancers.
- Monitor latency (`loadbalancing.googleapis.com/https/request_count`), error rates, and backend capacity.
- Use IAP (Identity-Aware Proxy) in front of internal Application LBs to enforce identity-based access.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_global_forwarding_rule`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | Global frontend IP and port binding |
| [`google_compute_forwarding_rule`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | Regional frontend IP and port binding |
| [`google_compute_backend_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | Backend group, health check, and LB policy |
| [`google_compute_url_map`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | URL path/host routing rules for Application LB |
| [`google_compute_target_https_proxy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | HTTPS proxy with SSL certificate |
| [`google_compute_ssl_certificate`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_certificate) | TLS certificate for HTTPS termination |
| [`google_compute_health_check`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | Backend health check definition |
| [`google_compute_backend_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket) | GCS bucket backend with optional CDN |

---

## Related Docs

- [Cloud Load Balancing Overview](https://cloud.google.com/load-balancing/docs)
- [Load Balancer Types Summary](https://cloud.google.com/load-balancing/docs/choosing-load-balancer)
- [Container-Native Load Balancing (NEGs)](https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing)
- [Cloud Armor (WAF / DDoS)](https://cloud.google.com/armor/docs)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
