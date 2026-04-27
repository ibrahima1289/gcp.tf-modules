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

## When and how to use each load balancer type

The table below maps every GCP load balancer type to its key decision criteria, ideal workloads, unsupported scenarios, and the Terraform `load_balancing_scheme` value to set.

| LB Type | Scope | Layer | Traffic | When to use | Don't use when | `load_balancing_scheme` | Key Terraform resources |
|---------|-------|-------|---------|-------------|----------------|------------------------|-------------------------|
| **[Global External Application LB](https://cloud.google.com/load-balancing/docs/https)** | Global | L7 | External | Public web apps, REST/gRPC APIs, SPAs served globally; need CDN, Cloud Armor, managed certs, or URL routing; Google anycast IP for lowest global latency | Backends are regional-only, internal-only, or protocol is raw TCP/UDP | `EXTERNAL_MANAGED` | `google_compute_global_forwarding_rule`, `google_compute_url_map`, `google_compute_backend_service` |
| **[Regional External Application LB](https://cloud.google.com/load-balancing/docs/https/regional-load-balancing)** | Regional | L7 | External | HTTP(S) apps that must stay within one region (data residency, low inter-region cost); same URL routing as global but scoped | Traffic needs to span regions or benefit from Google's global edge | `EXTERNAL_MANAGED` | `google_compute_forwarding_rule`, `google_compute_region_url_map`, `google_compute_region_backend_service` |
| **[Global External Proxy Network LB (SSL)](https://cloud.google.com/load-balancing/docs/ssl)** | Global | L4 | External | Non-HTTP apps that require TLS termination and global routing (e.g. MQTT, custom binary TLS protocols) | App speaks HTTP/HTTPS — use Application LB instead for richer routing | `EXTERNAL` | `google_compute_global_forwarding_rule`, `google_compute_target_ssl_proxy`, `google_compute_backend_service` |
| **[Global External Proxy Network LB (TCP)](https://cloud.google.com/load-balancing/docs/tcp)** | Global | L4 | External | Non-HTTP global TCP apps where TLS termination is not needed and client IP preservation is not required | Client IP must be preserved — use Passthrough NLB; app is HTTP(S) — use Application LB | `EXTERNAL` | `google_compute_global_forwarding_rule`, `google_compute_target_tcp_proxy`, `google_compute_backend_service` |
| **[Regional External Passthrough NLB](https://cloud.google.com/load-balancing/docs/network)** | Regional | L4 | External | Game servers, VoIP, UDP apps, custom TCP where client IP must be preserved; high-throughput or low-latency non-proxied traffic | URL routing or TLS termination is required; global routing is needed | `EXTERNAL` | `google_compute_forwarding_rule` → `backend_service` (no proxy), `google_compute_region_health_check` |
| **[Regional Internal Application LB](https://cloud.google.com/load-balancing/docs/l7-internal)** | Regional | L7 | Internal | Private microservices, internal APIs, service-mesh east-west HTTP/gRPC traffic inside a VPC; supports URL routing and IAP | Traffic originates outside the VPC, or protocol is raw TCP/UDP | `INTERNAL_MANAGED` | `google_compute_forwarding_rule`, `google_compute_region_url_map`, `google_compute_region_backend_service` |
| **[Regional Internal Passthrough NLB](https://cloud.google.com/load-balancing/docs/internal)** | Regional | L4 | Internal | Internal TCP/UDP workloads where client IP must reach the backend (DB proxies, syslog collectors, stateful TCP services inside a VPC) | URL routing is required; traffic is HTTP — use Internal Application LB | `INTERNAL` | `google_compute_forwarding_rule` → `backend_service` (no proxy), `google_compute_region_health_check` |
| **[Cross-region Internal Application LB](https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-cross-reg-internal)** | Global | L7 | Internal | Multi-region private HTTP/gRPC services where internal clients across regions need a single VIP; global anycast for internal traffic | Single-region; TCP/UDP internal traffic — use Regional Internal Passthrough NLB | `INTERNAL_MANAGED` | `google_compute_global_forwarding_rule`, `google_compute_url_map`, `google_compute_backend_service` |

---

### Quick decision guide

```text
Is traffic internal (VPC-only)?
  ├── Yes, HTTP/gRPC → Regional Internal Application LB  (INTERNAL_MANAGED)
  │                  → Cross-region Internal App LB if multi-region
  └── Yes, raw TCP/UDP → Regional Internal Passthrough NLB  (INTERNAL)

Is traffic external (internet-facing)?
  ├── HTTP / HTTPS / gRPC?
  │   ├── Need global routing / CDN / Armor → Global External Application LB  (EXTERNAL_MANAGED)
  │   └── Stay in one region               → Regional External Application LB  (EXTERNAL_MANAGED)
  └── Non-HTTP protocol?
      ├── Need TLS termination + global    → Global External Proxy Network LB — SSL  (EXTERNAL)
      ├── Raw TCP + global                 → Global External Proxy Network LB — TCP  (EXTERNAL)
      └── Raw TCP/UDP + client IP preserved → Regional External Passthrough NLB  (EXTERNAL)
```

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
