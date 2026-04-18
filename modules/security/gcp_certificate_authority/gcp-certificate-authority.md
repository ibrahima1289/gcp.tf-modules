# Google Cloud Certificate Authority Service (CAS)

Google Cloud Certificate Authority Service (CAS) is a managed private PKI service for issuing, managing, and revoking X.509 certificates within an organization. It eliminates the operational burden of running self-managed CA infrastructure while providing full control over certificate policies, issuance rules, and key custody.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

CAS provides a fully managed private CA hierarchy that integrates with Cloud KMS for key protection and IAM for access control. It is purpose-built for internal use cases — mTLS for service meshes, code signing, internal TLS for private services, IoT device identity, and SSH certificate issuance — where public CAs are inappropriate.

| Capability | Description |
|-----------|-------------|
| **Managed CA operations** | CA key generation, signing operations, and CRL/OCSP hosted by Google |
| **CA hierarchy** | Supports root CA, subordinate CA, and cross-signed CA topologies |
| **HSM-backed keys** | CA private keys can be stored in Cloud KMS HSM |
| **Certificate templates** | Reusable issuance policies controlling allowed extensions, key usages, and validity periods |
| **Revocation** | CRL and OCSP-based revocation; automated OCSP responses hosted by Google |
| **High-volume issuance** | DevOps tier supports thousands of short-lived certificates per second |
| **Audit logging** | All CA and certificate operations logged in Cloud Audit Logs |

---

## Core Concepts

### CA Pool

A CA Pool is a logical group of one or more CAs that share issuance policies and a common endpoint. Requests are load-balanced across CAs in the pool.

```
CA Pool
  ├── issuance_policy (allowed key types, lifetimes, extensions)
  ├── publishing_options (CRL/OCSP endpoints)
  └── CertificateAuthority (one or more)
        ├── type: SELF_SIGNED (root) or SUBORDINATE
        ├── key: Cloud KMS key reference
        └── config: subject, validity, CA constraints
```

### CA Types

| Type | Description | Use Case |
|------|-------------|---------|
| `SELF_SIGNED` | Root CA; self-signs its own certificate | Top of an internal PKI hierarchy |
| `SUBORDINATE` | Signed by a root CA (internal or external) | Intermediate CA for issuance; limits blast radius if compromised |

### Certificate Authority Tiers

| Tier | Issuance Rate | Cost Model | Use Case |
|------|--------------|-----------|---------|
| **Enterprise** | Low volume; slower | Higher per-certificate cost | Long-lived certificates, root/subordinate CAs |
| **DevOps** | High volume; fast (100s/sec) | Lower per-certificate cost | Short-lived workload certificates, mTLS, service mesh |

### Certificate Templates

Templates define reusable issuance policies applied to certificate requests:

| Policy Attribute | Description |
|-----------------|-------------|
| `predefined_values` | Forced key usage, extended key usage, and basic constraints |
| `identity_constraints` | Whether to allow SANs from CSR; reflection controls |
| `passthrough_extensions` | Which extensions from the CSR are passed through |
| `maximum_lifetime` | Maximum certificate validity period |

---

## Certificate Lifecycle

```
Request (CSR or config-based)
  → CA Pool (validates against issuance policy)
    → CertificateAuthority (signs with CA private key)
      → Certificate (X.509; stored in CAS)
        → Delivery (PEM bundle returned to caller)
          → Revocation (CRL/OCSP if needed)
            → Expiry / Renewal
```

### Certificate States

| State | Description |
|-------|-------------|
| `ACTIVE` | Valid and not revoked |
| `REVOKED` | Explicitly revoked; included in CRL |
| `EXPIRED` | Past the `not_after` date |

---

## Common Use Cases

| Use Case | CA Tier | Cert Lifetime | Notes |
|----------|---------|--------------|-------|
| Internal TLS for microservices (mTLS) | DevOps | Minutes to hours | High-volume, short-lived; works well with Workload Identity |
| GKE node/pod identity (mTLS mesh) | DevOps | Minutes | Integrate with cert-manager or Istio |
| Code signing | Enterprise | Days to months | Long-lived, low-volume |
| Internal HTTPS (ingress certs) | Enterprise | 30–90 days | Integrate with Certificate Manager |
| IoT device identity | DevOps or Enterprise | Months to years | One cert per device |
| SSH certificates | DevOps | Hours | Short-lived, no revocation needed |

---

## Integration with Certificate Manager

CAS integrates with Google Cloud Certificate Manager, which handles certificate delivery to load balancers and managed services. CAS acts as the issuance backend; Certificate Manager handles the binding to Google Cloud endpoints.

---

## Access Control

| Role | Permissions | Use Case |
|------|------------|---------|
| `roles/privateca.admin` | Full CA and pool management | PKI administrators |
| `roles/privateca.caManager` | Manage CAs within pools; no issuance | CA operations teams |
| `roles/privateca.certificateManager` | Issue and revoke certificates | Automated issuance pipelines |
| `roles/privateca.certificateRequester` | Request certificates only | Application workloads, cert-manager |
| `roles/privateca.auditor` | View certificates and CA metadata; no issuance | Compliance and audit |

---

## Security and Operations Guidance

- Use a **two-tier CA hierarchy** (offline root + online subordinate) for production PKIs — this protects the root key by keeping it inactive except during subordinate CA issuance.
- Store CA private keys in **Cloud KMS HSM** (`protection_level = "HSM"`) to satisfy compliance requirements for key custody.
- Prefer **short certificate lifetimes** with automated renewal over long-lived certs with complex revocation processes.
- Use **certificate templates** to enforce consistent key usage and extension policies across all issuance; do not allow unconstrained passthrough of CSR extensions.
- Enable **OCSP** alongside CRL for revocation to support clients that perform real-time revocation checks.
- Restrict issuance roles (`privateca.certificateRequester`) to workload service accounts; never grant issuance roles to end users.
- Monitor for unusual issuance patterns using Cloud Monitoring metrics and alerting on CA pool issuance rates.
- Document and test **CA compromise procedures** — know how to revoke all certificates issued by a compromised CA and re-issue from a new CA.
- Use **DevOps tier** for high-volume, short-lived certs; Enterprise tier for root/intermediate CAs and long-lived certificates.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_privateca_ca_pool` | Creates a CA pool with issuance policies | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_ca_pool) |
| `google_privateca_certificate_authority` | Creates a root or subordinate CA within a pool | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_certificate_authority) |
| `google_privateca_certificate` | Issues a certificate from a CA pool | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_certificate) |
| `google_privateca_certificate_template` | Creates a reusable certificate issuance policy template | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_certificate_template) |
| `google_privateca_ca_pool_iam_binding` | Authoritative IAM binding on a CA pool | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_ca_pool_iam) |
| `google_privateca_ca_pool_iam_member` | Additive IAM member on a CA pool | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_ca_pool_iam) |

---

## Related Docs

- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [GCP Cloud KMS Service Explainer](../gcp_cloud_kms/gcp-cloud-kms.md)
- [GCP Certificate Manager Service Explainer](../gcp_certificate_manager/gcp-certificate-manager.md)
- [GCP IAM Service Explainer](../gcp_iam/gcp-iam.md)
- [Release Notes](../../RELEASE.md)
