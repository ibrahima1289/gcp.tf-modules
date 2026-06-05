# GCP Cloud DNS Terraform Module

Reusable Terraform module for creating one or many [Cloud DNS](https://cloud.google.com/dns/docs) managed zones and record sets, supporting public, private, forwarding, and peering zone types with optional DNSSEC and traffic-routing policies.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "gcp_cloud_dns"
├── google_dns_managed_zone.zone              (one per zones[] entry where create = true)
│   ├── dynamic dnssec_config {}              (zone_type = "public" and dnssec_enabled = true)
│   ├── dynamic private_visibility_config {}  (zone_type ∈ {private, forwarding, peering})
│   ├── dynamic forwarding_config {}          (zone_type = "forwarding")
│   └── dynamic peering_config {}             (zone_type = "peering")
├── google_dns_record_set.simple              (records where routing_policy.enabled = false)
└── google_dns_record_set.routed              (records where routing_policy.enabled = true; WRR or GEO)
```

Data flow:

```text
var.zones[] + var.project_id + var.tags
        ↓
locals: zones_map       (create-filter + project resolve + label merge)
        records_all     (flattened, keyed "<zone_key>--<record_key>")
        records_simple  (routing_policy.enabled = false)
        records_routed  (routing_policy.enabled = true)
        ↓
google_dns_managed_zone → google_dns_record_set.simple
                        → google_dns_record_set.routed
        ↓
outputs: zone_ids, zone_name_servers, record_ids, common_tags
```

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |

---

## Resources Created

| Resource | Description |
|----------|-------------|
| [`google_dns_managed_zone`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | Public, private, forwarding, or peering DNS zone |
| [`google_dns_record_set`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | DNS record (A, AAAA, CNAME, MX, TXT, NS, PTR, SRV, CAA, SOA) |

---

## Variables

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default GCP project ID for all zones |
| `zones` | `list(object)` | One or many DNS zone configurations |

### Optional

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Accepted for interface consistency; Cloud DNS is a global service |
| `tags` | `map(string)` | `{}` | Common governance labels merged into every zone's label map |

### `zones[]` fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable `for_each` key |
| `name` | `string` | ✅ | — | Zone resource name (lowercase, no dots) |
| `dns_name` | `string` | ✅ | — | DNS domain with trailing dot, e.g. `example.com.` |
| `description` | `string` | ❌ | `""` | Human-readable zone description |
| `create` | `bool` | ❌ | `true` | Set `false` to skip without removing from config |
| `project_id` | `string` | ❌ | `""` | Per-zone project override |
| `zone_type` | `string` | ❌ | `public` | `public` \| `private` \| `forwarding` \| `peering` |
| `dnssec_enabled` | `bool` | ❌ | `false` | Enable DNSSEC (public zones only) |
| `dnssec_non_existence` | `string` | ❌ | `nsec3` | `nsec` or `nsec3` |
| `private_visibility_networks` | `list(string)` | ❌ | `[]` | VPC network self-links for private/forwarding/peering zones |
| `forwarding_targets` | `list(object)` | ❌ | `[]` | Upstream resolvers for forwarding zones |
| `peering_target_network` | `string` | ❌ | `""` | Target VPC URL for peering zones |
| `labels` | `map(string)` | ❌ | `{}` | Extra labels merged with common tags |
| `records` | `list(object)` | ❌ | `[]` | DNS record sets nested under this zone |

### `zones[].forwarding_targets[]` fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `ipv4_address` | `string` | ✅ | — | IPv4 address of the upstream resolver |
| `forwarding_path` | `string` | ❌ | `default` | `default` or `private` (use VPC for forwarding path) |

### `zones[].records[]` fields

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable key unique within the zone |
| `name` | `string` | ✅ | — | Full DNS name with trailing dot, e.g. `api.example.com.` |
| `type` | `string` | ✅ | — | Record type: `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`, `PTR`, `SRV`, `CAA`, `SOA` |
| `ttl` | `number` | ❌ | `300` | Time-to-live in seconds |
| `create` | `bool` | ❌ | `true` | Set `false` to skip this record |
| `rrdatas` | `list(string)` | ❌ | `[]` | Record data; leave empty when `routing_policy.enabled = true` |
| `routing_policy.enabled` | `bool` | ❌ | `false` | Activate routing policy (WRR or GEO) |
| `routing_policy.type` | `string` | ❌ | `WRR` | `WRR` (weighted round-robin) or `GEO` (geolocation) |
| `routing_policy.enable_geo_fencing` | `bool` | ❌ | `false` | Restrict GEO to matched regions only |
| `routing_policy.wrr_targets` | `list(object)` | ❌ | `[]` | WRR targets: `[{ weight, rrdatas }]` |
| `routing_policy.geo_targets` | `list(object)` | ❌ | `[]` | GEO targets: `[{ location, rrdatas }]` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `zone_ids` | Zone resource IDs keyed by zone key |
| `zone_names` | Zone resource names keyed by zone key |
| `zone_dns_names` | DNS domain names keyed by zone key |
| `zone_name_servers` | Authoritative NS list for each zone (use for registrar delegation) |
| `zone_visibility` | `public` or `private` for each zone |
| `record_ids` | Record IDs keyed by `<zone_key>--<record_key>` |
| `record_names` | Record DNS names keyed by `<zone_key>--<record_key>` |
| `zone_projects` | Resolved project IDs keyed by zone key |
| `common_tags` | Merged governance tags generated by this module |

---

## Usage

### Public zone with DNSSEC

```hcl
module "gcp_cloud_dns" {
  source = "../../modules/networking/gcp_cloud_dns"

  project_id = "my-project-id"

  tags = {
    environment = "production"
    team        = "platform"
  }

  zones = [
    {
      key            = "example-public"
      name           = "example-com"
      dns_name       = "example.com."
      zone_type      = "public"
      dnssec_enabled = true

      records = [
        { key = "apex-a",   name = "example.com.",     type = "A",   ttl = 300,  rrdatas = ["34.120.0.1"] },
        { key = "www-cname",name = "www.example.com.", type = "CNAME",ttl = 300, rrdatas = ["example.com."] },
        { key = "mx",       name = "example.com.",     type = "MX",  ttl = 3600, rrdatas = ["10 mail.example.com."] },
      ]
    }
  ]
}
```

### Private zone bound to a VPC

```hcl
zones = [
  {
    key       = "internal"
    name      = "internal-example-com"
    dns_name  = "internal.example.com."
    zone_type = "private"

    private_visibility_networks = [
      "projects/my-project-id/global/networks/my-vpc"
    ]

    records = [
      { key = "api", name = "api.internal.example.com.", type = "A", ttl = 60, rrdatas = ["10.0.1.5"] }
    ]
  }
]
```

### Forwarding zone to on-premises DNS

```hcl
zones = [
  {
    key       = "onprem"
    name      = "corp-onprem"
    dns_name  = "corp.example.com."
    zone_type = "forwarding"

    private_visibility_networks = ["projects/my-project-id/global/networks/my-vpc"]
    forwarding_targets = [
      { ipv4_address = "192.168.1.100", forwarding_path = "private" }
    ]
  }
]
```

### Weighted round-robin routing policy

```hcl
records = [
  {
    key  = "api-wrr"
    name = "api.example.com."
    type = "A"
    ttl  = 60
    routing_policy = {
      enabled = true
      type    = "WRR"
      wrr_targets = [
        { weight = 0.8, rrdatas = ["34.120.0.1"] },
        { weight = 0.2, rrdatas = ["34.120.0.2"] },
      ]
      enable_geo_fencing = false
      geo_targets        = []
    }
  }
]
```

---

## Related Docs

- [Cloud DNS Documentation](https://cloud.google.com/dns/docs)
- [Cloud DNS Pricing](https://cloud.google.com/dns/pricing)
- [google_dns_managed_zone](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone)
- [google_dns_record_set](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set)
- [Deployment Plan → tf-plans/gcp_cloud_dns](../../../tf-plans/gcp_cloud_dns/README.md)
- [Cloud DNS Service Explainer](gcp-cloud-dns.md)
