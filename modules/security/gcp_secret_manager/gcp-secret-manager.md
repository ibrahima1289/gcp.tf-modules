# Google Cloud Secret Manager

Google Cloud Secret Manager is a fully managed service for storing, accessing, and managing sensitive configuration data — API keys, passwords, certificates, database credentials, and other secrets — with fine-grained access control, automatic versioning, and audit logging built in.

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Overview

Secret Manager separates secrets from application code and configuration. Applications retrieve secret values at runtime via the API or client libraries, eliminating the need to embed credentials in source code, environment variables, or container images. Every access event is captured in Cloud Audit Logs.

| Capability | Description |
|-----------|-------------|
| **Versioning** | Each write creates a new version; previous versions remain accessible until disabled or destroyed |
| **IAM-based access** | Access is controlled per-secret using standard IAM roles |
| **Replication** | Automatic (Google-managed) or manual (user-defined) regional replication |
| **Encryption** | Encrypted at rest with Google-managed keys by default; CMEK with Cloud KMS supported |
| **Rotation** | Pub/Sub notifications on a rotation schedule to trigger rotation workflows |
| **Audit logging** | All access and admin operations captured in Cloud Audit Logs |

---

## Core Concepts

### Secret

A secret is a named container that holds one or more versions. The secret itself stores metadata — replication policy, labels, annotations, rotation configuration — but not the actual secret value.

```
Secret (resource)
  ├── name:        projects/my-project/secrets/db-password
  ├── replication: automatic / user-managed
  ├── labels:      { env: prod }
  └── rotation:    nextRotationTime, rotationPeriod
```

### Secret Version

A secret version holds the actual payload (the secret value). Versions are immutable once created; to update a secret, add a new version.

| Version State | Description |
|---------------|-------------|
| `ENABLED` | Active; can be accessed |
| `DISABLED` | Temporarily suppressed; cannot be accessed but preserved |
| `DESTROYED` | Permanently deleted; payload is gone |

Best practice: always access secrets by alias (`latest` or a specific version number) and avoid hardcoding version IDs in application code.

### Replication

| Mode | Description | Use Case |
|------|-------------|----------|
| **Automatic** | Google replicates to multiple regions transparently | Default; suitable for most workloads |
| **User-managed** | You specify which regions store the secret | Compliance, data residency, or latency requirements |

### Encryption (CMEK)

By default, secret payloads are encrypted with Google-managed keys. To use customer-managed encryption keys:

1. Create a Cloud KMS key ring and key in the same project.
2. Grant the Secret Manager service account the `roles/cloudkms.cryptoKeyEncrypterDecrypter` role on the key.
3. Reference the key in the secret's `customer_managed_encryption` block.

---

## Access Control

Secret Manager uses IAM to control who can create, read, manage, and destroy secrets.

### Key IAM Roles

| Role | Permissions | Use Case |
|------|------------|---------|
| `roles/secretmanager.admin` | Full access — create, update, delete secrets and versions | Secret lifecycle management |
| `roles/secretmanager.secretAccessor` | Access secret versions (read payload) | Application workloads reading secrets at runtime |
| `roles/secretmanager.secretVersionManager` | Add/disable/destroy versions | Rotation automation |
| `roles/secretmanager.viewer` | List secrets and view metadata; no payload access | Auditing, discovery |

Access can be granted at the **project level** (applies to all secrets) or at the **individual secret level** for fine-grained control.

### Recommended Access Pattern

```
Service Account (application workload)
  └── roles/secretmanager.secretAccessor
        scoped to: projects/my-project/secrets/db-password
```

---

## Secret Rotation

Secret Manager supports scheduled rotation via Pub/Sub notifications:

1. Set `rotation.rotation_period` and `rotation.next_rotation_time` on the secret.
2. Secret Manager publishes a message to a configured Pub/Sub topic at the rotation time.
3. A Cloud Function, Cloud Run service, or workflow receives the message and performs the actual rotation (generating a new secret value, adding a new version, disabling the old version).
4. The rotation schedule automatically advances to the next window.

```
Secret (rotation schedule)
  → Pub/Sub topic
    → Cloud Function / Cloud Run
      → New secret version added
      → Old version disabled
```

---

## Audit Logging

All Secret Manager operations are recorded in Cloud Audit Logs:

| Log Type | Events Captured |
|----------|----------------|
| **Admin Activity** | Secret creation, update, deletion; IAM policy changes | Always on |
| **Data Access** | `accessSecretVersion` calls (payload reads) | Must be enabled explicitly |

> Enable Data Access audit logs for Secret Manager in production environments. Every secret read is a security-relevant event.

---

## Security and Operations Guidance

- Enable **Data Access audit logs** for Secret Manager so that every secret read is recorded.
- Grant `roles/secretmanager.secretAccessor` at the **individual secret level**, not the project level, to enforce least-privilege access.
- Use **CMEK** (Cloud KMS) for secrets subject to regulatory requirements where Google-managed key custody is insufficient.
- Implement **secret rotation** using Pub/Sub-triggered workflows to eliminate long-lived credential exposure.
- Never store secret payloads in Terraform state — use `google_secret_manager_secret_version` with care, or inject values via CI/CD pipelines outside of Terraform.
- Use **Secret Manager's `latest` alias** in application references so rotation does not require application redeployment.
- Disable rather than destroy old secret versions until you are confident rotation was successful.
- Apply **VPC Service Controls** perimeters around Secret Manager to prevent data exfiltration from sensitive secrets.
- Label secrets with environment, team, and rotation owner metadata to simplify lifecycle management.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_secret_manager_secret` | Creates a secret with replication and rotation configuration | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) |
| `google_secret_manager_secret_version` | Adds a version (payload) to an existing secret | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) |
| `google_secret_manager_secret_iam_binding` | Authoritative IAM binding on a secret | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam) |
| `google_secret_manager_secret_iam_member` | Additive IAM member on a secret | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam) |
| `google_secret_manager_regional_secret` | Creates a secret pinned to a single region | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_regional_secret) |

---

## Related Docs

- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [GCP IAM Service Explainer](../gcp_iam/gcp-iam.md)
- [GCP Cloud KMS Service Explainer](../gcp_cloud_kms/gcp-cloud-kms.md)
- [Release Notes](../../RELEASE.md)
