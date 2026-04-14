# Google Cloud Storage

## Service overview

[Google Cloud Storage (GCS)](https://cloud.google.com/storage/docs) is Google Cloud's managed object storage service. It stores arbitrary data as objects within buckets — each object has a key, data payload, and metadata. GCS is designed for 99.999999999% (11 nines) annual durability. There is no file system hierarchy; objects are addressed by bucket name and object key.

GCS is the foundational storage layer for data lakes, analytics pipelines, ML datasets, static content hosting, and backup/archival workflows.

---

## How Cloud Storage works

```text
Client (API / gsutil / gcloud / SDK)
      |
Bucket (globally unique name, regional or multi-regional)
  ├── Object: logs/2026-01-01/app.log   (Standard class)
  ├── Object: data/exports/jan-2025.csv (Nearline class, 30-day min)
  └── Object: backups/archive-2023.tar  (Coldline class, 90-day min)
      |
Lifecycle rules → auto-transition between classes, or delete after N days
```

---

## Storage classes

| Class | Access frequency | Min storage duration | Use case |
|-------|-----------------|---------------------|----------|
| **Standard** | Frequent (hot data) | None | Active data, websites, analytics staging |
| **Nearline** | ~1x/month | 30 days | Monthly backups, log archives |
| **Coldline** | ~1x/quarter | 90 days | Quarterly backups, disaster recovery copies |
| **Archive** | ~1x/year | 365 days | Long-term regulatory archives, cold audit data |

> Retrieval from Nearline/Coldline/Archive incurs an additional per-byte retrieval fee. Choose the class based on how frequently you read the data.

---

## Location types

| Location type | Description | Best for |
|--------------|-------------|----------|
| **Single-region** | Data stored in one region | Lowest latency to co-located compute; lowest cost |
| **Dual-region** | Data replicated across two specific regions | Resilience + low-latency from two locations |
| **Multi-region** | Data replicated across a geographic area (US, EU, ASIA) | Global access, highest availability |

---

## Access control models

| Model | Description | When to use |
|-------|-------------|-------------|
| **Uniform bucket-level access** | IAM policies only; ACLs disabled | Recommended — simpler and auditable |
| **Fine-grained access (legacy)** | IAM + per-object ACLs | Legacy apps depending on per-object ACLs |

> Google recommends **uniform bucket-level access** for all new buckets.

---

## Key features

| Feature | Description |
|---------|-------------|
| **Object versioning** | Retains previous versions on overwrite/delete; enables recovery |
| **Retention policies** | Objects cannot be deleted or modified for a defined period (compliance) |
| **Object hold** | Event-based or temporary hold preventing deletion during litigation/review |
| **Lifecycle rules** | Auto-transition storage class or delete objects based on age, version count, etc. |
| **Requestor pays** | Charge the requester for operations and egress, not the bucket owner |
| **Signed URLs** | Time-limited URLs for authorized object access without IAM credentials |
| **Customer-managed encryption keys (CMEK)** | Encrypt objects with keys from Cloud KMS |

---

## When to use Cloud Storage

- Data is unstructured and object-based (files, images, videos, logs, datasets).
- You need durable, highly available storage with lifecycle controls.
- Workloads require global accessibility or region-flexible placement.
- You are building a data lake or analytics staging area.
- Backups and archives need automated class transitions over time.

---

## Core capabilities

- Multiple storage classes for cost-performance tradeoffs.
- Object versioning, retention, and legal-hold support.
- IAM and uniform bucket-level access controls.
- Regional, dual-region, and multi-region placement options.
- Lifecycle rules for automated transitions and expiration.
- Signed URLs and signed policy documents for delegated access.

---

## Real-world usage

- Data lake ingestion zones and analytics staging buckets.
- Long-term regulatory archives (WORM-compatible with retention policies).
- Static asset and media content hosting with CDN integration.
- ML training dataset storage for Vertex AI and Dataflow jobs.
- GKE backup storage (Velero backups to GCS).
- Cross-region disaster recovery object replication.

---

## Security and operations guidance

- Enforce uniform bucket-level access and disable legacy ACLs on all new buckets.
- Block public access at the organization policy level (`constraints/storage.publicAccessPrevention`).
- Use CMEK (Cloud KMS) for buckets containing PII or regulated data.
- Define lifecycle rules to transition cold data and automatically delete expired objects.
- Enable audit logging for bucket admin activity and data access on sensitive buckets.
- Use VPC Service Controls to prevent exfiltration of sensitive datasets.
- Monitor egress costs and per-bucket request patterns with Cloud Monitoring.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_storage_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | Creates a GCS bucket with lifecycle, versioning, and encryption settings |
| [`google_storage_bucket_iam_binding`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_binding) | Grants IAM roles on a bucket |
| [`google_storage_bucket_object`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | Uploads an object to a bucket (for config files, scripts, etc.) |
| [`google_storage_default_object_access_control`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_default_object_access_control) | Default ACLs on new objects (fine-grained mode only) |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `storage.googleapis.com` API |

---

## Related Docs

- [Google Cloud Storage Overview](https://cloud.google.com/storage/docs)
- [Storage Classes](https://cloud.google.com/storage/docs/storage-classes)
- [Object Lifecycle Management](https://cloud.google.com/storage/docs/lifecycle)
- [Uniform Bucket-Level Access](https://cloud.google.com/storage/docs/uniform-bucket-level-access)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
