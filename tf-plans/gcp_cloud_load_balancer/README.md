# GCP Cloud Load Balancer — Terraform Deployment Plan

This deployment plan wires variable definitions to the
[`gcp_cloud_load_balancer`](../../modules/networking/gcp_cloud_load_balancer/README.md)
module and provides a `terraform.tfvars` template covering all four load-balancer
families supported by the module.

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | Compute Engine API enabled |
| IAM | `roles/compute.loadBalancerAdmin` or `roles/compute.admin` |

Backend targets (MIGs or NEGs) must be created before setting `create = true`
on any load-balancer entry.

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Configure the plan
cp terraform.tfvars terraform.auto.tfvars
# Edit terraform.auto.tfvars — update project_id, region, and backends

# 3. Initialise and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Load Balancer Types

| Variable | LB Family | Layer | Scope |
|----------|-----------|-------|-------|
| `global_http_lbs` | Global External Application LB | L7 HTTP/HTTPS | Global |
| `regional_http_lbs` | Regional Application LB | L7 HTTP/HTTPS | Regional |
| `network_lbs` | External Passthrough NLB | L4 TCP/UDP | Regional |
| `internal_lbs` | Internal Passthrough NLB | L4 TCP/UDP | Regional (VPC) |

Set `create = false` on entries whose backends do not yet exist — the entry
remains in state as a no-op and can be enabled later without changing keys.

---

## File Reference

| File | Purpose |
|------|---------|
| `main.tf` | Module call |
| `variables.tf` | Input variable declarations |
| `locals.tf` | `created_date` helper |
| `outputs.tf` | Pass-through of all module outputs |
| `providers.tf` | Google provider + Terraform version pin |
| `terraform.tfvars` | Example values for all four LB types |

---

## Key Variables

### Global External Application LB (`global_http_lbs`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | string | required | Unique map key |
| `create` | bool | `true` | Set `false` to skip creation |
| `name` | string | required | Resource name prefix |
| `enable_https` | bool | `false` | Create HTTPS proxy + managed cert |
| `ssl_domains` | list(string) | `[]` | Domains for managed SSL certificate |
| `ssl_cert_ids` | list(string) | `[]` | Existing certificate self-links |
| `reserve_ip_address` | bool | `false` | Reserve a static global IP |
| `load_balancing_scheme` | string | `EXTERNAL_MANAGED` | `EXTERNAL_MANAGED` or `EXTERNAL` |
| `backend_service_name` | string | required | Name for the backend service |
| `protocol` | string | `HTTP` | Backend protocol: `HTTP`, `HTTPS`, `HTTP2` |
| `enable_cdn` | bool | `false` | Enable Cloud CDN on the backend |
| `backends[].group` | string | required | Instance group or NEG self-link |

### Regional Application LB (`regional_http_lbs`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `load_balancing_scheme` | string | `EXTERNAL_MANAGED` | `EXTERNAL_MANAGED` or `INTERNAL_MANAGED` |
| `network` / `subnetwork` | string | `""` | Required for `INTERNAL_MANAGED` |
| `region` | string | `""` | Overrides `var.region` when non-empty |

### External Passthrough NLB (`network_lbs`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `protocol` | string | `TCP` | `TCP` or `UDP` |
| `ports` | list(string) | `[]` | Specific ports (empty = all when `all_ports = true`) |
| `all_ports` | bool | `false` | Forward all ports |

### Internal Passthrough NLB (`internal_lbs`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `network` | string | required | VPC network self-link |
| `subnetwork` | string | required | Subnet self-link |
| `global_access` | bool | `false` | Allow cross-region access |

---

## Outputs

| Output | Description |
|--------|-------------|
| `global_http_lb_ips` | Reserved global static IPs |
| `global_http_lb_forwarding_rule_ips` | Assigned global forwarding rule IPs |
| `global_http_lb_backend_service_ids` | Global backend service self-links |
| `global_http_lb_url_map_ids` | Global URL map self-links |
| `regional_http_lb_ips` | Reserved regional static IPs |
| `regional_http_lb_forwarding_rule_ips` | Regional application LB forwarding rule IPs |
| `regional_http_lb_backend_service_ids` | Regional application LB backend service self-links |
| `network_lb_ips` | Reserved external passthrough NLB IPs |
| `network_lb_forwarding_rule_ips` | External passthrough NLB forwarding rule IPs |
| `internal_lb_forwarding_rule_ips` | Internal passthrough NLB forwarding rule IPs |
| `common_labels` | Merged labels applied to all resources |

---

## Destroy

```bash
terraform destroy
```

> Resources are destroyed in reverse dependency order. Forwarding rules are
> removed before proxies, proxies before URL maps, URL maps before backend
> services.

---

*Back to [GCP Module Service List](../../gcp-module-service-list.md)*
