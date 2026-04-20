# GCP Cloud Logging Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for managing [Google Cloud Logging](https://cloud.google.com/logging/docs) resources at the project level. Supports creating custom **log buckets**, **log sinks** (export to GCS, BigQuery, Pub/Sub, or log buckets), project-wide **log exclusions**, and **log-based metrics** for Cloud Monitoring.

---

## Architecture

```text
GCP Project
└── Cloud Logging
    │
    ├── Log Router
    │   ├── Log Sinks ────────────────► GCS Bucket      (archival / compliance)
    │   │   (google_logging_project_sink)  BigQuery Dataset (SQL analysis / SIEM)
    │   │                                  Pub/Sub Topic    (real-time processing)
    │   │                                  Log Bucket       (cross-project aggregation)
    │   │
    │   └── Log Exclusions ──────────► /dev/null         (drop before ingestion)
    │       (google_logging_project_exclusion)
    │
    ├── Log Buckets ─────────────────► Retention 1–3650 days
    │   (google_logging_project_bucket_config)  Log Analytics (BigQuery SQL)
    │                                           CMEK (Cloud KMS)
    │
    └── Log-Based Metrics ───────────► Cloud Monitoring Metrics
        (google_logging_metric)            Alert Policies
                                           Dashboards

  Sink IAM  (managed outside this module)
  └── writer_identity ─────────────► roles/storage.objectCreator   (GCS)
                                      roles/bigquery.dataEditor      (BigQuery)
                                      roles/pubsub.publisher         (Pub/Sub)
                                      roles/logging.bucketWriter     (Log bucket)
```

---

## Resources Created

| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| Log Bucket | `google_logging_project_bucket_config` | Custom log storage with retention, Log Analytics, CMEK |
| Log Sink | `google_logging_project_sink` | Export filtered logs to GCS, BigQuery, Pub/Sub, or log bucket |
| Log Exclusion | `google_logging_project_exclusion` | Drop matching entries before ingestion to reduce cost |
| Log-Based Metric | `google_logging_metric` | Convert log entries into Cloud Monitoring metrics |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5 |
| hashicorp/google | >= 6.0 |

---

## Variables

### Top-Level

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID |
| `region` | `string` | | `"us-central1"` | Provider region |
| `tags` | `map(string)` | | `{}` | Governance labels merged into all resources |

### `log_buckets` — List of Log Bucket Objects

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this bucket entry |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `bucket_id` | `string` | ✅ | — | Unique bucket ID within the project |
| `location` | `string` | | `"global"` | `global` or a GCP region |
| `retention_days` | `number` | | `30` | Log retention in days (1–3650) |
| `description` | `string` | | `""` | Human-readable description |
| `locked` | `bool` | | `false` | Prevent retention reduction or deletion |
| `enable_analytics` | `bool` | | `false` | Enable Log Analytics (BigQuery SQL) |
| `kms_key_name` | `string` | | `""` | Cloud KMS key URI for CMEK; empty = Google-managed |

### `log_sinks` — List of Log Sink Objects

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this sink entry |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `name` | `string` | ✅ | — | Sink resource name |
| `destination` | `string` | ✅ | — | Full destination URI (GCS / BigQuery / Pub/Sub / log bucket) |
| `filter` | `string` | | `""` | Logging filter; empty = export all logs |
| `description` | `string` | | `""` | Human-readable description |
| `unique_writer_identity` | `bool` | | `true` | `true` = per-sink service account; `false` = shared logging SA |
| `bigquery_options.use_partitioned_tables` | `bool` | | `true` | Partition BigQuery export tables by timestamp |
| `exclusions[*].name` | `string` | ✅ | — | Exclusion rule name |
| `exclusions[*].filter` | `string` | ✅ | — | Filter for entries to drop at this sink |
| `exclusions[*].description` | `string` | | `""` | Description for the exclusion |
| `exclusions[*].disabled` | `bool` | | `false` | Pause exclusion without deleting |

### `log_exclusions` — List of Exclusion Objects

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this exclusion entry |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `name` | `string` | ✅ | — | Exclusion resource name |
| `description` | `string` | | `""` | Human-readable description |
| `filter` | `string` | ✅ | — | Cloud Logging filter for entries to drop |
| `disabled` | `bool` | | `false` | Pause exclusion without deleting |

### `log_metrics` — List of Log-Based Metric Objects

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this metric entry |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `name` | `string` | ✅ | — | Metric name as it appears in Cloud Monitoring |
| `description` | `string` | | `""` | Human-readable description |
| `filter` | `string` | ✅ | — | Cloud Logging filter for entries to count/measure |
| `metric_kind` | `string` | | `"DELTA"` | `DELTA` \| `GAUGE` \| `CUMULATIVE` |
| `value_type` | `string` | | `"INT64"` | `INT64` \| `DISTRIBUTION` \| `BOOL` \| `DOUBLE` \| `STRING` |
| `unit` | `string` | | `"1"` | `"1"` for counts; `"ms"` for latency |
| `display_name` | `string` | | `""` | Display name in Cloud Monitoring console |
| `labels[*].key` | `string` | ✅ | — | Label key |
| `labels[*].value_type` | `string` | | `"STRING"` | `STRING` \| `BOOL` \| `INT64` |
| `labels[*].description` | `string` | | `""` | Label description |
| `label_extractors` | `map(string)` | | `{}` | Map of label key → `EXTRACT()` or `REGEXP_EXTRACT()` expression |
| `value_extractor` | `string` | | `""` | Field extractor for DISTRIBUTION value (e.g. `EXTRACT(jsonPayload.latency)`) |
| `bucket_options` | `object` | | `null` | Histogram buckets for DISTRIBUTION metrics (linear / exponential / explicit) |

---

## Outputs

| Name | Description |
|------|-------------|
| `log_bucket_ids` | Log bucket IDs keyed by bucket key |
| `log_bucket_names` | Log bucket full resource names keyed by bucket key |
| `log_sink_ids` | Log sink IDs keyed by sink key |
| `log_sink_writer_identities` | Per-sink writer service account identities — grant these on the destination resource |
| `log_exclusion_ids` | Log exclusion IDs keyed by exclusion key |
| `log_metric_ids` | Log-based metric IDs keyed by metric key |
| `log_metric_names` | Log-based metric names (use in Cloud Monitoring filters) keyed by metric key |
| `common_labels` | Governance labels generated by this module call |

---

## Usage

### Minimal — single sink to GCS

```hcl
module "gcp_cloud_logging" {
  source     = "../../modules/monitoring_devops/gcp_cloud_logging"
  project_id = "my-project"

  log_sinks = [
    {
      key         = "error-archive"
      name        = "error-archive"
      destination = "storage.googleapis.com/my-log-archive-bucket"
      filter      = "severity >= ERROR"
    }
  ]

  tags = { environment = "production", team = "platform" }
}

# Grant the sink's writer identity write access to the GCS bucket
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = "my-log-archive-bucket"
  role   = "roles/storage.objectCreator"
  member = module.gcp_cloud_logging.log_sink_writer_identities["error-archive"]
}
```

### Full — buckets, sinks, exclusions, metrics

```hcl
module "gcp_cloud_logging" {
  source     = "../../modules/monitoring_devops/gcp_cloud_logging"
  project_id = var.project_id
  region     = var.region

  log_buckets = [
    {
      key              = "security-logs"
      bucket_id        = "security-logs"
      location         = "us-central1"
      retention_days   = 365
      enable_analytics = true
      description      = "Security and audit log storage with Log Analytics enabled"
    }
  ]

  log_sinks = [
    {
      key                    = "audit-to-bq"
      name                   = "audit-to-bigquery"
      destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/audit_logs"
      filter                 = "logName:(\"activity\" OR \"data_access\")"
      unique_writer_identity = true
      bigquery_options       = { use_partitioned_tables = true }
    }
  ]

  log_exclusions = [
    {
      key         = "drop-health-checks"
      name        = "drop-health-check-200s"
      description = "Drop GKE health check 200 responses to reduce ingestion volume"
      filter      = "resource.type=\"k8s_container\" httpRequest.status=200 httpRequest.requestUrl:\"/healthz\""
    }
  ]

  log_metrics = [
    {
      key         = "iam-changes"
      name        = "iam-policy-changes"
      description = "Count of IAM SetIamPolicy calls"
      filter      = "protoPayload.methodName=\"SetIamPolicy\""
      metric_kind = "DELTA"
      value_type  = "INT64"
      labels = [
        { key = "resource_type", value_type = "STRING", description = "Resource type modified" }
      ]
      label_extractors = { resource_type = "EXTRACT(resource.type)" }
    }
  ]

  tags = { environment = "production", team = "security" }
}
```

---

## Sink IAM

When `unique_writer_identity = true` (the default), each sink gets its own service account. You must grant it the appropriate role on the destination **outside this module**, using the `log_sink_writer_identities` output:

| Destination | Required Role |
|-------------|--------------|
| GCS Bucket | `roles/storage.objectCreator` |
| BigQuery Dataset | `roles/bigquery.dataEditor` |
| Pub/Sub Topic | `roles/pubsub.publisher` |
| Log Bucket | `roles/logging.bucketWriter` |

---

## Related Docs

- [Cloud Logging Explainer](gcp-cloud-logging.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Cloud Monitoring Module](../gcp_cloud_monitoring/README.md)
- [google_logging_project_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink)
- [google_logging_project_bucket_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_bucket_config)
- [google_logging_project_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion)
- [google_logging_metric](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_metric)
