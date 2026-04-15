# Google Cloud Key Management Service (Cloud KMS)

Google Cloud Key Management Service (Cloud KMS) is a managed cryptographic key lifecycle service. It provides centralized creation, storage, rotation, and destruction of encryption keys, and exposes a consistent API for encrypt, decrypt, sign, and verify operations across Google Cloud services and customer applications.

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Overview

Cloud KMS separates key custody from data storage. Services that support customer-managed encryption keys (CMEK) use Cloud KMS keys to encrypt data, while the key material itself never leaves the KMS boundary. This satisfies regulatory and compliance requirements for key custody, rotation auditability, and access separation.

| Capability | Description |
|-----------|-------------|
| **Symmetric encryption** | AES-256-GCM keys for encrypt/decrypt operations |
| **Asymmetric encryption** | RSA keys for asymmetric encrypt/decrypt |
| **Asymmetric signing** | RSA/EC keys for digital signatures (JWT, code signing, TLS) |
| **MAC signing** | HMAC keys for message authentication codes |
| **Hardware-backed keys (HSM)** | Keys protected in FIPS 140-2 Level 3 hardware security modules |
| **External key management (EKM)** | Keys stored in an external key manager; Cloud KMS proxies operations |
| **Automatic rotation** | Keys rotate on a configurable schedule; old versions remain for decryption |

---

## Core Concepts

### Resource Hierarchy

```
Project
  └── Key Ring  (regional container for keys)
        └── CryptoKey  (logical key with policy and rotation schedule)
              └── CryptoKey Version  (actual key material; one is primary at a time)
```

| Resource | Description |
|----------|-------------|
| **Key Ring** | Regional container; groups related keys. Key rings cannot be deleted — plan naming carefully. |
| **CryptoKey** | A named key with a purpose, rotation period, and IAM policy. Immutable purpose after creation. |
| **CryptoKey Version** | A specific version of the key material. Only one version is `PRIMARY` at a time. |

### Key Purposes

| Purpose | Algorithm Options | Use Cases |
|---------|------------------|-----------|
| `ENCRYPT_DECRYPT` | `GOOGLE_SYMMETRIC_ENCRYPTION` (AES-256) | CMEK for GCS, BigQuery, Compute disks, Secret Manager, etc. |
| `ASYMMETRIC_DECRYPT` | RSA 2048/3072/4096 OAEP | Asymmetric envelope encryption |
| `ASYMMETRIC_SIGN` | RSA PKCS1/PSS, EC P-256/P-384 | JWT signing, code signing, certificate issuance |
| `MAC` | HMAC-SHA-256/384/512 | Message authentication codes |

### Protection Levels

| Level | Description | Compliance |
|-------|-------------|-----------|
| `SOFTWARE` | Key material stored in Google's software HSM boundary | Standard |
| `HSM` | Key material stored in a FIPS 140-2 Level 3 certified HSM; higher cost | PCI-DSS, FedRAMP High, HIPAA |
| `EXTERNAL` | Key material stored in an external key manager (EKM); Cloud KMS proxies operations | Bring-your-own-key (BYOK) scenarios |
| `EXTERNAL_VPC` | EKM accessible only via VPC | Highest isolation for external keys |

---

## Key Rotation

CryptoKeys support automatic rotation via `rotation_period`. When a rotation occurs:

1. A new CryptoKey Version is created and set as `PRIMARY`.
2. The previous version remains `ENABLED` and can still decrypt data encrypted with it.
3. New encrypt operations use the new primary version automatically.
4. Old versions can be manually disabled or destroyed after all dependent data has been re-encrypted.

```
CryptoKey
  ├── rotation_period: 7776000s  (90 days)
  └── next_rotation_time: 2026-07-14T00:00:00Z

Versions:
  ├── v3: PRIMARY (current)
  ├── v2: ENABLED (can still decrypt)
  └── v1: DESTROYED
```

> **Re-encryption is not automatic.** After rotation, data is encrypted with the new primary on the next write. Existing data remains encrypted with the version that was primary at write time until explicitly re-encrypted.

---

## CMEK Integration

Cloud KMS provides CMEK support to a wide range of Google Cloud services. The pattern is consistent:

1. Create a KMS key in the same region as the target resource.
2. Grant the service's service agent the `roles/cloudkms.cryptoKeyEncrypterDecrypter` IAM role on the key.
3. Reference the key's resource name in the resource configuration.

### Common CMEK Integrations

| Service | IAM Principal | Terraform Attribute |
|---------|--------------|---------------------|
| Cloud Storage | `service-{proj_number}@gs-project-accounts.iam.gserviceaccount.com` | `encryption.default_kms_key_name` |
| BigQuery | `bq-{proj_number}@bigquery-encryption.iam.gserviceaccount.com` | `encryption_configuration.kms_key_name` |
| Compute Engine disks | `service-{proj_number}@compute-system.iam.gserviceaccount.com` | `disk_encryption_key.kms_key_self_link` |
| Secret Manager | `service-{proj_number}@gcp-sa-secretmanager.iam.gserviceaccount.com` | `customer_managed_encryption.kms_key_name` |
| Cloud SQL | `service-{proj_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com` | `encryption_key_name` |
| Artifact Registry | `service-{proj_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com` | `kms_key_name` |

---

## Access Control

Cloud KMS uses IAM at both the key ring and individual key level.

| Role | Permissions | Use Case |
|------|------------|---------|
| `roles/cloudkms.admin` | Full lifecycle management | Key administrators |
| `roles/cloudkms.cryptoKeyEncrypterDecrypter` | Encrypt and decrypt using a key | Service agents for CMEK, application encryption |
| `roles/cloudkms.cryptoKeyEncrypter` | Encrypt only | Write-only encryption workloads |
| `roles/cloudkms.cryptoKeyDecrypter` | Decrypt only | Read-only decryption workloads |
| `roles/cloudkms.signer` | Sign using asymmetric/MAC keys | Code signing, JWT issuance |
| `roles/cloudkms.signerVerifier` | Sign and verify | TLS certificate operations |
| `roles/cloudkms.viewer` | View key metadata; no cryptographic operations | Auditing |

---

## Audit Logging

All Cloud KMS operations are captured in Cloud Audit Logs:

| Log Type | Events Captured |
|----------|----------------|
| **Admin Activity** | Key ring and key creation, deletion, IAM changes, version state changes | Always on |
| **Data Access** | Encrypt, decrypt, sign, verify API calls | Must be enabled explicitly |

> Enable Data Access audit logs for Cloud KMS in regulated environments so every cryptographic operation is attributable.

---

## Security and Operations Guidance

- Keep key rings and keys in the **same region** as the resources they protect — cross-region KMS calls add latency and complicate compliance.
- Use **HSM protection level** for keys protecting regulated data (PCI, HIPAA, FedRAMP) — the cost delta is modest compared to compliance value.
- Never grant `roles/cloudkms.admin` to service accounts used for encryption operations — separate key admin from key usage.
- Use **automatic rotation** for CMEK keys and set rotation periods aligned to your compliance policy (commonly 90 days).
- Use **key-level IAM** rather than project-level KMS roles to enforce least-privilege per service.
- Enable **Data Access audit logs** to capture every encrypt/decrypt call for compliance and incident investigation.
- Plan key ring names carefully — **key rings cannot be deleted**; use a naming convention that will not conflict with future rings.
- Apply **Organization Policy** (`constraints/gcp.restrictCmekCryptoKeyProjects`) to enforce that specific services only use CMEK keys from approved projects.
- Use **VPC Service Controls** to prevent exfiltration of key material via API calls from outside a perimeter.
- Implement **break-glass procedures** — document and test the process for re-enabling a disabled key or recovering data if key material is inadvertently destroyed.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_kms_key_ring` | Creates a key ring in a region | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) |
| `google_kms_crypto_key` | Creates a CryptoKey with purpose, rotation, and protection level | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) |
| `google_kms_crypto_key_version` | Manages an individual key version (enable/disable/destroy) | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_version) |
| `google_kms_key_ring_iam_binding` | Authoritative IAM binding on a key ring | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_key_ring_iam) |
| `google_kms_key_ring_iam_member` | Additive IAM member on a key ring | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_key_ring_iam) |
| `google_kms_crypto_key_iam_binding` | Authoritative IAM binding on a CryptoKey | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_crypto_key_iam) |
| `google_kms_crypto_key_iam_member` | Additive IAM member on a CryptoKey | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_crypto_key_iam) |
| `google_kms_key_ring_import_job` | Imports externally generated key material into Cloud KMS | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring_import_job) |

---

## Related Docs

- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [GCP IAM Service Explainer](../gcp_iam/gcp-iam.md)
- [GCP Secret Manager Service Explainer](../gcp_secret_manager/gcp-secret-manager.md)
- [GCP Certificate Authority Service Explainer](../gcp_certificate_authority/gcp-certificate-authority.md)
- [Release Notes](../../RELEASE.md)
