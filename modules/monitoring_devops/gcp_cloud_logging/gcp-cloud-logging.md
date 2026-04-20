# Google Cloud Logging

[Cloud Logging](https://cloud.google.com/logging/docs) is a fully managed, real-time log management service that ingests, indexes, and stores log data from GCP services, user applications, and hybrid/multicloud environments. It integrates with Cloud Monitoring for log-based metrics and alerting, and provides **Log Analytics** (BigQuery-backed SQL querying) for operational and security investigations.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Auto-ingestion** | GCP services write logs automatically — no agent needed for managed services |
| **Log Router** | Rules-based engine that routes logs to sinks (GCS, BigQuery, Pub/Sub, Logging buckets) |
| **Log Buckets** | Storage containers with configurable retention and optional Log Analytics |
| **Log Sinks** | Export destinations for filtered log streams |
| **Log-based Metrics** | Convert log entries into Cloud Monitoring metrics |
| **Log Analytics** | SQL querying over log data stored in upgraded Log Analytics buckets |
| **Exclusions** | Drop noisy log entries before ingestion to reduce cost |
| **Field-level encryption** | CMEK for log storage using Cloud KMS |

---

## Core Concepts

### Log Types

| Type | Description | Examples |
|------|-------------|---------|
| **Platform logs** | Written by GCP services automatically | Cloud Storage access logs, GKE audit logs |
| **User-written logs** | Written by application code via Logging API or client libraries | App errors, business events |
| **Structured logs** | JSON-formatted log entries with queryable fields | `httpRequest`, `jsonPayload` |
| **Admin Activity logs** | Who did what to which resource (always on, no charge) | `CreateInstance`, `SetIamPolicy` |
| **Data Access logs** | Reads/writes to resource data (off by default) | BigQuery reads, GCS object access |
| **System Event logs** | Automated GCP system actions | Live migration, auto-repair |
| **Policy Denied logs** | IAM/VPC-SC denials | Access denied by org policy |

### Log Router and Sinks

The **Log Router** processes every incoming log entry against sink inclusion/exclusion filters before persisting or exporting:

```text
Log Entry
    │
    ▼
Log Router
    ├── _Required bucket  (Admin Activity, System Event — 400-day retention, immutable)
    ├── _Default bucket   (everything else — 30-day default retention)
    ├── Custom sinks  ──► GCS / BigQuery / Pub/Sub / custom Log bucket
    └── Exclusions    ──► discard matching entries
```

```hcl
# Export all ERROR logs to GCS for long-term archival
resource "google_logging_project_sink" "error_archive" {
  name        = "error-archive"
  destination = "storage.googleapis.com/${google_storage_bucket.log_archive.name}"
  filter      = "severity >= ERROR"

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.log_archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.error_archive.writer_identity
}
```

### Sink Destinations

| Destination | Terraform Resource | Use Case |
|-------------|-------------------|---------|
| Cloud Storage | `google_logging_project_sink` with `storage.googleapis.com/...` | Long-term archival, compliance |
| BigQuery | `google_logging_project_sink` with `bigquery.googleapis.com/...` | SQL analysis, SIEM feeds |
| Pub/Sub | `google_logging_project_sink` with `pubsub.googleapis.com/...` | Real-time processing, SIEM integration |
| Log bucket | `google_logging_project_sink` with `logging.googleapis.com/...` | Cross-project aggregation, Log Analytics |

### Log Buckets

```hcl
resource "google_logging_project_bucket_config" "security_logs" {
  project          = var.project_id
  location         = "global"
  bucket_id        = "security-logs"
  retention_days   = 365
  enable_analytics = true   # enables Log Analytics (BigQuery-backed SQL)

  cmek_settings {
    kms_key_name = google_kms_crypto_key.log_key.id
  }
}
```

### Exclusions (Cost Reduction)

```hcl
resource "google_logging_project_exclusion" "noisy_health_checks" {
  name        = "drop-health-check-logs"
  description = "Drop GKE ingress health check 200s to reduce ingestion volume"
  filter      = "resource.type=\"k8s_container\" httpRequest.status=200 httpRequest.requestUrl:\"/healthz\""
}
```

### Organization and Folder Sinks

Aggregate logs from all projects under an org or folder:

```hcl
resource "google_logging_organization_sink" "org_audit" {
  name             = "org-audit-to-bq"
  org_id           = var.org_id
  destination      = "bigquery.googleapis.com/projects/${var.logging_project}/datasets/audit_logs"
  filter           = "logName:\"activity\""
  include_children = true

  bigquery_options {
    use_partitioned_tables = true
  }
}
```

---

## Log-Based Metrics

```hcl
resource "google_logging_metric" "iam_changes" {
  name        = "iam-policy-changes"
  description = "Count of IAM policy SetIamPolicy calls"
  filter      = "protoPayload.methodName=\"SetIamPolicy\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    labels {
      key        = "resource_type"
      value_type = "STRING"
    }
  }

  label_extractors = {
    resource_type = "EXTRACT(resource.type)"
  }
}
```

---

## Retention Defaults

| Bucket | Default Retention | Configurable |
|--------|-------------------|-------------|
| `_Required` | 400 days | No |
| `_Default` | 30 days | Yes (1–3650 days) |
| Custom buckets | User-defined | Yes (1–3650 days) |

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_logging_project_sink` | Export project logs to GCS, BigQuery, Pub/Sub, or log bucket |
| `google_logging_folder_sink` | Export folder-scoped logs |
| `google_logging_organization_sink` | Export org-scoped logs (all projects) |
| `google_logging_project_bucket_config` | Create/configure log storage buckets |
| `google_logging_project_exclusion` | Drop log entries before ingestion |
| `google_logging_folder_exclusion` | Drop entries at folder scope |
| `google_logging_organization_exclusion` | Drop entries at org scope |
| `google_logging_metric` | Create log-based metrics for Cloud Monitoring |

---

## Security Guidance

- Enable **Data Access audit logs** (DATA_READ, DATA_WRITE) for sensitive services — they are off by default and can generate significant volume; target only what you need.
- Route Admin Activity logs to a **locked GCS bucket** or a separate security project that developers cannot access.
- Use **org-level sinks with `include_children = true`** to ensure no project can opt out of centralized audit log export.
- Apply **CMEK** to custom log buckets storing sensitive data using Cloud KMS.
- Set **log exclusions** for noisy health check and debug entries to reduce ingestion cost — always test exclusion filters against `_Default` first.
- Grant `roles/logging.viewer` for read access; `roles/logging.admin` only to the logging automation SA.
- Enable **Log Analytics** on security log buckets to allow SQL-based investigation without exporting to BigQuery.

---

## Related Docs

- [Cloud Logging Overview](https://cloud.google.com/logging/docs/overview)
- [Log Router and Sinks](https://cloud.google.com/logging/docs/export/configure_export_v2)
- [Log Buckets](https://cloud.google.com/logging/docs/buckets)
- [Log Analytics](https://cloud.google.com/logging/docs/log-analytics)
- [Audit Logs](https://cloud.google.com/logging/docs/audit)
- [Pricing](https://cloud.google.com/stackdriver/pricing)
- [google_logging_project_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink)
- [google_logging_project_bucket_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_bucket_config)
