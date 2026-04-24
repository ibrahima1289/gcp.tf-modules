# GCP Cloud Load Balancer Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for deploying all four families of [Google Cloud Load Balancing](https://cloud.google.com/load-balancing/docs/load-balancing-overview). Each load balancer type is independently optional — create any combination in a single module call.

---

## Architecture

```text
Internet / VPC
      │
      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Forwarding Rule  (IP address + port + protocol)                        │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Application LBs (Layer 7)          Passthrough LBs (Layer 4)    │   │
│  │                                                                  │   │
│  │  Target HTTP/HTTPS Proxy            ── no proxy ──               │   │
│  │        │                                                         │   │
│  │  URL Map (host / path routing)                                   │   │
│  │        │                                   │                     │   │
│  │  Backend Service ◄──────────────── Backend Service               │   │
│  │        │   health_checks                   │   health_checks     │   │
│  │        ▼                                   ▼                     │   │
│  │  Instance Groups / NEGs           Instance Groups                │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

Load Balancer Types (all optional, any combination)
─────────────────────────────────────────────────────
  global_http_lbs      → Global External Application LB  (HTTP/HTTPS, global anycast)
  regional_http_lbs    → Regional Application LB         (HTTP/HTTPS, external or internal VPC)
  network_lbs          → Regional External Passthrough NLB (TCP/UDP, client IP preserved)
  internal_lbs         → Regional Internal Passthrough NLB (TCP/UDP, VPC-only)
```

---

## Resources Created

| Variable | Resource(s) Created | LB Layer | Scope |
|----------|---------------------|----------|-------|
| `global_http_lbs` | `google_compute_global_forwarding_rule` · `google_compute_target_http_proxy` / `google_compute_target_https_proxy` · `google_compute_url_map` · `google_compute_backend_service` · `google_compute_health_check` · `google_compute_global_address` (opt) · `google_compute_managed_ssl_certificate` (opt) | L7 | Global |
| `regional_http_lbs` | `google_compute_forwarding_rule` · `google_compute_region_target_http_proxy` / `google_compute_region_target_https_proxy` · `google_compute_region_url_map` · `google_compute_region_backend_service` · `google_compute_region_health_check` · `google_compute_address` (opt) | L7 | Regional |
| `network_lbs` | `google_compute_forwarding_rule` · `google_compute_region_backend_service` · `google_compute_region_health_check` · `google_compute_address` (opt) | L4 passthrough | Regional |
| `internal_lbs` | `google_compute_forwarding_rule` · `google_compute_region_backend_service` · `google_compute_region_health_check` | L4 passthrough | Regional |

> Backend instance groups and VPC networks are **not** created by this module — reference them by self-link.

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5 |
| hashicorp/google | >= 6.0 |

---

## Usage

### Global External HTTPS Application LB

```hcl
module "load_balancers" {
  source     = "../../modules/networking/gcp_cloud_load_balancer"
  project_id = "my-project-id"
  region     = "us-central1"
  tags       = { environment = "production", team = "platform" }

  global_http_lbs = [
    {
      key                  = "web-global"
      name                 = "web-global-lb"
      enable_https         = true
      ssl_domains          = ["app.example.com"]
      reserve_ip_address   = true
      backend_service_name = "web-backend"
      enable_cdn           = true
      url_map_name         = "web-url-map"

      health_check = {
        name         = "web-hc"
        protocol     = "HTTP"
        port         = 8080
        request_path = "/healthz"
      }

      backends = [
        {
          group          = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/instanceGroupManagers/web-mig"
          balancing_mode = "UTILIZATION"
          max_utilization = 0.8
        }
      ]
    }
  ]
}
```

### Regional Internal Application LB (VPC-private)

```hcl
global_http_lbs = []

regional_http_lbs = [
  {
    key                   = "api-internal"
    name                  = "api-internal-lb"
    load_balancing_scheme = "INTERNAL_MANAGED"
    network               = "projects/my-project/global/networks/prod-vpc"
    subnetwork            = "projects/my-project/regions/us-central1/subnetworks/prod-subnet"
    backend_service_name  = "api-internal-backend"
    url_map_name          = "api-internal-url-map"

    health_check = {
      name         = "api-internal-hc"
      protocol     = "HTTP"
      request_path = "/health"
    }

    backends = [
      {
        group = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/instanceGroups/api-mig"
      }
    ]
  }
]
```

### Regional External Passthrough NLB (TCP, client IP preserved)

```hcl
network_lbs = [
  {
    key                = "game-nlb"
    name               = "game-server-nlb"
    protocol           = "UDP"
    all_ports          = true
    reserve_ip_address = true

    health_check = {
      name     = "game-hc"
      protocol = "TCP"
      port     = 7777
    }

    backends = [
      {
        group          = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/instanceGroups/game-mig"
        balancing_mode = "CONNECTION"
      }
    ]
  }
]
```

### Regional Internal Passthrough NLB

```hcl
internal_lbs = [
  {
    key        = "db-proxy-ilb"
    name       = "db-proxy-internal"
    network    = "projects/my-project/global/networks/prod-vpc"
    subnetwork = "projects/my-project/regions/us-central1/subnetworks/data-subnet"
    protocol   = "TCP"
    ports      = ["5432"]
    global_access = true  # allow cross-region VPC traffic

    health_check = {
      name = "db-proxy-hc"
      port = 5432
    }

    backends = [
      {
        group = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/instanceGroups/db-proxy-mig"
      }
    ]
  }
]
```

---

## Variables

### Common

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID |
| `region` | `string` | | `us-central1` | Default region for regional resources |
| `tags` | `map(string)` | | `{}` | Common governance labels |

### `global_http_lbs[*]`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key |
| `create` | `bool` | | `true` | Set `false` to skip |
| `name` | `string` | ✅ | — | Base name for all resources |
| `enable_https` | `bool` | | `false` | Create HTTPS proxy on port 443 |
| `ssl_domains` | `list(string)` | | `[]` | Domains for Google-managed SSL cert |
| `ssl_cert_ids` | `list(string)` | | `[]` | Pre-existing cert self-links |
| `reserve_ip_address` | `bool` | | `false` | Reserve a global static anycast IP |
| `load_balancing_scheme` | `string` | | `EXTERNAL_MANAGED` | `EXTERNAL_MANAGED` or `EXTERNAL` |
| `backend_service_name` | `string` | ✅ | — | Backend service resource name |
| `protocol` | `string` | | `HTTP` | `HTTP`, `HTTPS`, or `HTTP2` |
| `session_affinity` | `string` | | `NONE` | `NONE`, `CLIENT_IP`, `GENERATED_COOKIE` |
| `timeout_sec` | `number` | | `30` | Backend timeout in seconds |
| `enable_cdn` | `bool` | | `false` | Enable Cloud CDN |
| `backends` | `list(object)` | ✅ | — | Instance groups / NEGs |
| `health_check` | `object` | ✅ | — | Health check config |
| `url_map_name` | `string` | ✅ | — | URL map resource name |
| `enable_logging` | `bool` | | `false` | Enable request logging |
| `log_sample_rate` | `number` | | `1.0` | Fraction of requests to log |

### `regional_http_lbs[*]`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key |
| `create` | `bool` | | `true` | Set `false` to skip |
| `name` | `string` | ✅ | — | Base name |
| `region` | `string` | | `""` | Per-entry region override |
| `load_balancing_scheme` | `string` | | `EXTERNAL_MANAGED` | `EXTERNAL_MANAGED` or `INTERNAL_MANAGED` |
| `enable_https` | `bool` | | `false` | Create HTTPS proxy on port 443 |
| `ssl_cert_ids` | `list(string)` | | `[]` | Pre-existing regional cert IDs |
| `network` | `string` | | `""` | Required for `INTERNAL_MANAGED` |
| `subnetwork` | `string` | | `""` | Required for `INTERNAL_MANAGED` |
| `reserve_ip_address` | `bool` | | `false` | Reserve a regional static IP |
| `backend_service_name` | `string` | ✅ | — | Backend service name |
| `protocol` | `string` | | `HTTP` | `HTTP`, `HTTPS`, or `HTTP2` |
| `backends` | `list(object)` | ✅ | — | Instance groups / NEGs |
| `health_check` | `object` | ✅ | — | Health check config |
| `url_map_name` | `string` | ✅ | — | URL map resource name |

### `network_lbs[*]`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key |
| `create` | `bool` | | `true` | Set `false` to skip |
| `name` | `string` | ✅ | — | Base name |
| `region` | `string` | | `""` | Per-entry region override |
| `protocol` | `string` | | `TCP` | `TCP` or `UDP` |
| `all_ports` | `bool` | | `false` | Forward all ports |
| `ports` | `list(string)` | | `[]` | Specific ports, e.g. `["80","443"]` |
| `reserve_ip_address` | `bool` | | `false` | Reserve external static IP |
| `backends` | `list(object)` | ✅ | — | Instance groups |
| `health_check` | `object` | ✅ | — | Health check config |

### `internal_lbs[*]`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key |
| `create` | `bool` | | `true` | Set `false` to skip |
| `name` | `string` | ✅ | — | Base name |
| `region` | `string` | | `""` | Per-entry region override |
| `protocol` | `string` | | `TCP` | `TCP` or `UDP` |
| `all_ports` | `bool` | | `false` | Forward all ports |
| `ports` | `list(string)` | | `[]` | Specific ports |
| `network` | `string` | ✅ | — | VPC network self-link |
| `subnetwork` | `string` | ✅ | — | Subnet self-link |
| `global_access` | `bool` | | `false` | Allow cross-region VPC traffic |
| `backends` | `list(object)` | ✅ | — | Instance groups |
| `health_check` | `object` | ✅ | — | Health check config |

---

## Outputs

| Name | Description |
|------|-------------|
| `global_http_lb_ips` | Reserved global IPs keyed by LB key |
| `global_http_lb_forwarding_rule_ids` | Global forwarding rule IDs |
| `global_http_lb_forwarding_rule_ips` | Effective IPs (reserved or ephemeral) |
| `global_http_backend_service_ids` | Global backend service IDs |
| `global_http_url_map_ids` | Global URL map IDs |
| `regional_http_lb_ips` | Reserved regional IPs keyed by LB key |
| `regional_http_lb_forwarding_rule_ids` | Regional app LB forwarding rule IDs |
| `regional_http_lb_forwarding_rule_ips` | Effective regional app LB IPs |
| `regional_http_backend_service_ids` | Regional backend service IDs |
| `network_lb_ips` | External passthrough NLB IPs |
| `network_lb_forwarding_rule_ids` | Passthrough NLB forwarding rule IDs |
| `network_lb_forwarding_rule_ips` | Effective passthrough NLB IPs |
| `internal_lb_forwarding_rule_ids` | Internal NLB forwarding rule IDs |
| `internal_lb_forwarding_rule_ips` | Internal NLB IP addresses |
| `common_labels` | Governance labels generated by this module |

---

## Notes

- **Backend prerequisites**: Instance groups, regional MIGs, and NEGs must exist before applying this module. Use the [Autoscaling module](../gcp_autoscaling/README.md) to create regional MIGs with autoscalers.
- **Managed SSL certs**: Provision time is 60–90 minutes after the domain resolves to the forwarding rule IP. Set `ssl_domains` only when DNS is already pointed.
- **HTTPS proxy and certs**: For `global_http_lbs`, set `ssl_domains` to let Google manage the cert, or pass `ssl_cert_ids` for self-managed certs. For `regional_http_lbs`, only `ssl_cert_ids` is supported (create `google_compute_region_ssl_certificate` outside this module).
- **Internal LBs**: The forwarding rule IP is assigned from the specified subnetwork range. Set `global_access = true` to allow on-premises or cross-region traffic via Cloud Interconnect/VPN.
- **all_ports vs ports**: Set `all_ports = true` for passthrough NLBs that need to forward every port (e.g. third-party appliances). Otherwise, specify exact `ports`.
