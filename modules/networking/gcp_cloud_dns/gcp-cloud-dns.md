# Google Cloud DNS

## Service overview

[Google Cloud DNS](https://cloud.google.com/dns/docs) is a managed, authoritative DNS platform built on Google's global infrastructure. It provides low-latency DNS query resolution for both public internet domains and private VPC-internal service discovery. Cloud DNS supports standard DNS record types, advanced routing policies, and DNSSEC for public zones.

---

## How Cloud DNS works

```text
DNS client (VM, browser, external user)
  └── DNS query for api.example.com
        |
Cloud DNS resolver
  ├── Public zone (internet-resolvable) → returns external IP
  └── Private zone (VPC-bound) → returns internal/private IP
        |
Record set: api.example.com → A → 10.10.1.5
```

---

## Zone types

| Zone type | Description | Visible to |
|-----------|-------------|------------|
| **Public zone** | Internet-resolvable; name servers delegated from your registrar | All internet resolvers |
| **Private zone** | VPC-bound resolution; not resolvable from the internet | Specified VPC networks only |
| **Forwarding zone** | Forwards queries for a domain to external resolvers (on-prem DNS) | Configured networks |
| **Peering zone** | Delegates queries from one VPC to a zone owned by another VPC | Producer/consumer VPC pair |
| **Reverse lookup zone** | Resolves IP → hostname (PTR records) | Configured networks |
| **Managed reverse lookup** | Auto-generated PTR records for GCP resources | Configured networks |

---

## Record types

| Record | Description | Example |
|--------|-------------|---------|
| **A** | IPv4 address | `api.example.com → 34.x.x.x` |
| **AAAA** | IPv6 address | `api.example.com → 2600::1` |
| **CNAME** | Canonical name (alias) | `www → api.example.com` |
| **MX** | Mail exchange server | `example.com → mail.example.com` |
| **TXT** | Text (SPF, DKIM, domain verification) | `v=spf1 include:...` |
| **NS** | Name server delegation | Zone apex delegation record |
| **SOA** | Start of authority | Zone metadata |
| **PTR** | Reverse lookup | `5.1.10.10.in-addr.arpa → api.example.com` |
| **SRV** | Service locator | `_sip._tcp.example.com` |
| **CAA** | Certificate Authority Authorization | Which CAs can issue TLS certs |

---

## DNS routing policies

| Policy | Description | Use case |
|--------|-------------|----------|
| **Weighted round-robin** | Distribute queries proportionally by weight | Traffic splitting, gradual migration |
| **Geolocation** | Return different answers based on client region | Region-specific endpoints, latency reduction |
| **Failover** | Primary + backup record set; switch on health check failure | Active-passive DR routing |
| **Latency-based** | Route to lowest-latency regional endpoint | Multi-region active-active services |

---

## DNSSEC

Cloud DNS supports DNSSEC for public zones to protect against DNS spoofing and cache poisoning attacks. When enabled, all zone records are signed with cryptographic keys, and resolvers can verify authenticity of DNS responses.

---

## When to use Cloud DNS

- You host internet-facing domain records for websites, APIs, or services.
- Internal service resolution is required across VPCs.
- DNS management must be reliable, versioned, and auditable.
- You need advanced routing (weighted, geo, failover) for multi-region architectures.
- Hybrid connectivity requires DNS forwarding to on-premises resolvers.

---

## Core capabilities

- Public and private managed DNS zones with IAM-governed access.
- Advanced routing policies: weighted, geo, latency, and failover.
- DNS forwarding and peering for hybrid and multi-VPC architectures.
- DNSSEC for public zone integrity and spoofing protection.
- High-availability global serving with 100% uptime SLA for public zones.

---

## Real-world usage

- Public web and API domain resolution (apex and subdomain records).
- Private service discovery in Shared VPC environments.
- Hybrid DNS: forwarding internal domains to on-premises nameservers.
- Disaster recovery DNS failover: switch endpoints based on health checks.
- Split-horizon DNS: same domain resolves differently inside vs outside VPC.

---

## Security and operations guidance

- Restrict DNS zone management with IAM (`roles/dns.admin`, `roles/dns.editor`) and audit all changes.
- Enable DNSSEC for all public zones to protect against spoofing attacks.
- Use private zones for internal service names; never expose internal IPs in public zones.
- Separate zone ownership by team or environment (e.g., `prod.example.com`, `dev.example.com`).
- Standardize TTL policies: shorter for frequently-changing records, longer for stable records.
- Use DNS peering zones in Shared VPC to let service projects resolve host project DNS records.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_dns_managed_zone`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | Creates a public or private DNS zone |
| [`google_dns_record_set`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | Creates or updates a DNS record within a zone |
| [`google_dns_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_policy) | Configures DNS server policy (forwarding, alternative nameservers) |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `dns.googleapis.com` API |

---

## Related Docs

- [Cloud DNS Overview](https://cloud.google.com/dns/docs)
- [DNS Zone Types](https://cloud.google.com/dns/docs/zones)
- [DNS Routing Policies](https://cloud.google.com/dns/docs/routing-policies-overview)
- [DNSSEC Overview](https://cloud.google.com/dns/docs/dnssec)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
