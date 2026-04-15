# Google Cloud Certificate Manager

Google Cloud Certificate Manager is a managed service for provisioning, deploying, and renewing TLS/SSL certificates at scale on Google Cloud load balancers and other supported endpoints. It supports Google-managed certificates (automatic issuance and renewal), self-managed certificates (bring your own), and certificates issued from a private CA via Certificate Authority Service.

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Overview

Certificate Manager decouples certificate lifecycle management from load balancer configuration. Rather than attaching certificates directly to load balancer target proxies (the legacy approach), Certificate Manager uses certificate maps to define which certificates apply to which domains and endpoints — enabling large-scale, multi-domain deployments with zero-touch renewal.

| Capability | Description |
|-----------|-------------|
| **Google-managed certs** | Automatic issuance and renewal via Google Trust Services or Let's Encrypt |
| **Self-managed certs** | Upload your own certificate PEM and private key |
| **Private CA certs** | Issue certificates from Certificate Authority Service (CAS) |
| **Certificate maps** | Routing table that associates domain names to certificates on a load balancer |
| **DNS and HTTP authorization** | Domain ownership validation for Google-managed certificates |
| **Wildcard certificates** | Wildcard (`*.example.com`) supported for Google-managed certificates |
| **Regional and global** | Supports both global external and regional load balancers |

---

## Core Concepts

### Certificate

A Certificate resource holds certificate metadata and (for self-managed) the PEM payload. For Google-managed certificates, Certificate Manager handles issuance and renewal automatically.

| Certificate Type | Key Source | Renewal | Use Case |
|-----------------|-----------|---------|---------|
| `MANAGED` (Google) | Google Trust Services / Let's Encrypt | Automatic | Public internet-facing endpoints |
| `SELF_MANAGED` | Customer-supplied PEM | Manual | Certificates from internal/external CAs |
| Private CA (`MANAGED` + CAS) | Certificate Authority Service | Automatic | Internal endpoints; private PKI |

### Domain Authorization

Before issuing a Google-managed certificate for a domain, Certificate Manager must verify domain ownership:

| Method | Description | Use Case |
|--------|-------------|---------|
| **DNS authorization** | Add a CNAME record to your DNS zone pointing to a Google-owned token | Recommended; works for wildcard certs and non-HTTP traffic |
| **Load balancer authorization** | Serve an HTTP challenge token via the load balancer | Simpler setup; requires HTTP traffic to the domain |

DNS authorizations are standalone resources (`google_certificate_manager_dns_authorization`) that can be reused across multiple certificates for the same domain.

### Certificate Map

A certificate map is a routing table attached to a load balancer. It contains one or more map entries, each binding a hostname matcher to a specific certificate.

```
CertificateMap (attached to load balancer)
  └── CertificateMapEntry
        ├── hostname: "api.example.com"   (specific host match)
        └── certificates: [cert-resource]

  └── CertificateMapEntry
        ├── hostname: "*"                  (default/catch-all)
        └── certificates: [wildcard-cert]
```

The load balancer selects the certificate matching the SNI hostname from the client TLS handshake.

### Legacy vs. Certificate Manager

| Feature | Legacy (direct SSL cert on LB) | Certificate Manager |
|---------|-------------------------------|---------------------|
| Max certs per proxy | ~15 | Hundreds per map |
| Renewal | Manual or per-cert auto-renew | Centralized auto-renew |
| Multi-domain control | Per-cert SAN list | Certificate map entries |
| Private CA integration | Limited | Native via CAS |
| Wildcard support | Limited | Full support |

---

## Supported Load Balancers

| Load Balancer Type | Certificate Map Support |
|-------------------|------------------------|
| Global external Application LB (classic + Envoy) | ✅ |
| Regional external Application LB | ✅ |
| Regional internal Application LB | ✅ |
| External proxy Network LB (SSL proxy) | ✅ |
| Classic Application LB (legacy) | ✅ (via direct SSL cert attachment — not maps) |

---

## Certificate Lifecycle

```
DnsAuthorization (proves domain ownership)
  → Certificate (MANAGED or SELF_MANAGED)
    → CertificateMap
      → CertificateMapEntry (hostname → certificate)
        → Attached to TargetHttpsProxy / TargetSslProxy
          → Load Balancer serves TLS with correct cert per SNI
```

### Google-Managed Certificate States

| State | Description |
|-------|-------------|
| `PROVISIONING` | Waiting for domain validation or CA issuance |
| `FAILED_NOT_VISIBLE` | DNS/HTTP challenge not yet resolvable |
| `FAILED_CAA_CHECKING` | CAA DNS record blocking issuance |
| `ACTIVE` | Issued and serving |
| `RENEWAL_FAILED` | Auto-renewal attempt failed |

---

## Security and Operations Guidance

- Use **DNS authorization** instead of load balancer authorization for new deployments — it supports wildcard certificates and works even before traffic is flowing to the load balancer.
- Prefer **certificate maps** over directly attaching certificates to load balancers for any deployment with more than a few certificates or domains.
- Use **wildcard certificates** (`*.example.com`) to reduce the number of certificate resources and authorization challenges for multi-subdomain deployments.
- Monitor certificate states via Cloud Monitoring and alert on `RENEWAL_FAILED` or certificates approaching expiry.
- For **private CA integration**, use Certificate Authority Service in DevOps tier with short-lived certificates and automatic renewal; avoid long-lived self-managed certs for internal services.
- Apply IAM least-privilege — grant `roles/certificatemanager.editor` only to automation accounts; restrict `roles/certificatemanager.owner` to PKI administrators.
- Validate **CAA DNS records** are configured correctly for your domain before provisioning Google-managed certificates to avoid issuance failures.
- Use **self-managed certificates** when certificate pinning, specific CA chains, or compliance requirements mandate a specific issuer.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_certificate_manager_certificate` | Creates a managed or self-managed certificate | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate) |
| `google_certificate_manager_dns_authorization` | Creates a DNS authorization for domain ownership validation | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_dns_authorization) |
| `google_certificate_manager_certificate_map` | Creates a certificate map for load balancer attachment | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate_map) |
| `google_certificate_manager_certificate_map_entry` | Adds a hostname-to-certificate mapping entry | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate_map_entry) |
| `google_certificate_manager_certificate_issuance_config` | Links a CA pool (CAS) as the backend for managed certificate issuance | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate_issuance_config) |
| `google_certificate_manager_trust_config` | Configures trust anchors for mutual TLS on load balancers | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_trust_config) |

---

## Related Docs

- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [GCP Certificate Authority Service Explainer](../gcp_certificate_authority/gcp-certificate-authority.md)
- [GCP Cloud KMS Service Explainer](../gcp_cloud_kms/gcp-cloud-kms.md)
- [GCP IAM Service Explainer](../gcp_iam/gcp-iam.md)
- [Release Notes](../../RELEASE.md)
