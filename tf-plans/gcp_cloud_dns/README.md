# GCP Cloud DNS Deployment Plan

Wrapper configuration for the [GCP Cloud DNS module](../../modules/networking/gcp_cloud_dns/README.md). Deploys one or many DNS managed zones (public, private, forwarding, peering) and their record sets, with optional DNSSEC and traffic-routing policies.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_cloud_dns/
├── providers.tf       → Terraform requirements, GCS backend (optional), google provider
├── variables.tf       → project_id, region, tags, zones[]
├── locals.tf          → created_date
├── main.tf            → module "gcp_cloud_dns" wrapper call
├── outputs.tf         → pass-through outputs from module
├── terraform.tfvars   → example multi-zone configuration
└── README.md          → this file
        ↓
modules/networking/gcp_cloud_dns/
├── google_dns_managed_zone.zone
├── google_dns_record_set.simple
└── google_dns_record_set.routed
```

---

## Prerequisites

- GCP project with [Cloud DNS API](https://console.cloud.google.com/apis/library/dns.googleapis.com) enabled (`dns.googleapis.com`)
- Terraform `>= 1.5` and Google provider `>= 6.0`
- Authenticated Application Default Credentials (`gcloud auth application-default login`)
- IAM role: `roles/dns.admin` on target project(s)

---

## Apply Workflow

```bash
# 1. Authenticate
gcloud auth application-default login --no-launch-browser

# 2. Set project
gcloud config set project my-project-id

# 3. Enable Cloud DNS API
gcloud services enable dns.googleapis.com --project=my-project-id

# 4. Update terraform.tfvars with your zones and records

# 5. Initialise
terraform init

# 6. Review plan
terraform plan -out=tfplan

# 7. Apply
terraform apply tfplan

# 8. Retrieve name servers for registrar delegation (public zones)
terraform output zone_name_servers
```

> **DNSSEC note**: After enabling DNSSEC on a public zone, retrieve the DS record from the GCP console and add it at your domain registrar to complete the chain of trust.

---

## Variables

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default GCP project ID |
| `zones` | `list(object)` | One or many DNS zone definitions |

### Optional

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Interface consistency only; Cloud DNS is global |
| `tags` | `map(string)` | `{}` | Common governance labels |

For the full nested `zones[]` schema, see the [module variable reference](../../modules/networking/gcp_cloud_dns/README.md#variables).

---

## Example Configurations

### Minimal public zone

```hcl
zones = [
  {
    key      = "myzone"
    name     = "my-example-com"
    dns_name = "my-example.com."
    records  = [
      { key = "apex", name = "my-example.com.", type = "A", ttl = 300, rrdatas = ["34.1.2.3"] }
    ]
  }
]
```

### Private zone for VPC service discovery

```hcl
zones = [
  {
    key       = "internal"
    name      = "internal-svc"
    dns_name  = "svc.internal."
    zone_type = "private"
    private_visibility_networks = ["projects/my-project/global/networks/my-vpc"]
    records = [
      { key = "api", name = "api.svc.internal.", type = "A", ttl = 30, rrdatas = ["10.0.0.5"] }
    ]
  }
]
```

### Forwarding zone to on-premises resolver

```hcl
zones = [
  {
    key       = "onprem"
    name      = "corp-internal"
    dns_name  = "corp.internal."
    zone_type = "forwarding"
    private_visibility_networks = ["projects/my-project/global/networks/my-vpc"]
    forwarding_targets = [
      { ipv4_address = "10.100.0.2", forwarding_path = "private" }
    ]
  }
]
```

### Skip a zone without removing it from config

```hcl
zones = [
  { key = "old-zone", name = "old-example-com", dns_name = "old.example.com.", create = false }
]
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `zone_ids` | Zone resource IDs keyed by zone key |
| `zone_names` | Zone resource names keyed by zone key |
| `zone_dns_names` | DNS domain names keyed by zone key |
| `zone_name_servers` | Authoritative NS list (needed for registrar delegation) |
| `zone_visibility` | `public` or `private` per zone |
| `record_ids` | Record IDs keyed by `<zone_key>--<record_key>` |
| `record_names` | Record DNS names keyed by `<zone_key>--<record_key>` |
| `zone_projects` | Resolved project IDs keyed by zone key |
| `common_tags` | Merged governance tags used in this run |

---

## Related Docs

- [GCP Cloud DNS Module](../../modules/networking/gcp_cloud_dns/README.md)
- [Cloud DNS Documentation](https://cloud.google.com/dns/docs)
- [Cloud DNS Record Types](https://cloud.google.com/dns/docs/overview#supported_dns_record_types)
- [Cloud DNS Pricing](https://cloud.google.com/dns/pricing)
- [DNSSEC Setup Guide](https://cloud.google.com/dns/docs/dnssec)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
