# GCP Pub/Sub — Terraform Module

Terraform module for deploying [Google Cloud Pub/Sub](https://cloud.google.com/pubsub/docs) **topics**, **subscriptions** (Pull, Push, BigQuery, and Cloud Storage), **schemas** (Avro / Protobuf), **dead-letter topics**, and **IAM bindings** across multiple entries in a single module call.

> Back to [GCP Module Service List](../../../gcp-module-service-list.md)

---

## Architecture

```text
var.schemas (list)          var.topics (list)
      │                           │
      ▼                           ▼
google_pubsub_schema      google_pubsub_topic ◄── schema_settings (optional)
                                  │                kms_key_name   (optional)
                                  │                retention      (optional)
                    fan-out (one topic → many subscriptions)
          ┌─────────────┬──────────────┬──────────────────┐
          ▼             ▼              ▼                   ▼
      Pull sub      Push sub      BigQuery sub        GCS sub
   (app polls)  (HTTP POST     (writes to BQ       (writes files
                 to endpoint)   table directly)     to GCS bucket)
          │
   Dead-letter topic  ◄── messages exceeding max_delivery_attempts
          │
   google_pubsub_topic_iam_member       (Step 5)
   google_pubsub_subscription_iam_member (Step 6)
```

---

## Resources Created

| Step | Resource | Description |
|------|----------|-------------|
| 1 | `google_pubsub_schema` | Avro or Protobuf schema for message validation |
| 2 | `google_pubsub_topic` | Message channel with optional CMEK, retention, schema |
| 3 | `google_pubsub_topic` (DLT) | Dead-letter topic per subscription that enables dead-lettering |
| 4 | `google_pubsub_subscription` | Pull, Push, BigQuery, or GCS subscription |
| 5 | `google_pubsub_topic_iam_member` | Publisher / subscriber IAM on topics |
| 6 | `google_pubsub_subscription_iam_member` | Subscriber IAM on subscriptions |

---

## Requirements

| Requirement | Version |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | `pubsub.googleapis.com` |
| IAM (deployer) | `roles/pubsub.admin` |

---

## Usage Examples

### Example 1 — Pull Subscription with Dead-Letter

```hcl
module "pubsub" {
  source     = "../../modules/app_development/Pub_Sub"
  project_id = "my-gcp-project"
  region     = "us-central1"
  tags       = { env = "prod", team = "platform" }

  topics = [
    {
      key  = "orders"
      name = "orders"
      message_retention_duration = "86400s" # 1 day topic retention
      iam_bindings = [
        { role = "roles/pubsub.publisher", member = "serviceAccount:order-svc@my-gcp-project.iam.gserviceaccount.com" }
      ]
    }
  ]

  subscriptions = [
    {
      key                            = "orders-worker"
      name                           = "orders-worker"
      topic_key                      = "orders"
      ack_deadline_seconds           = 60
      dead_letter_key                = "orders-worker"
      dead_letter_max_delivery_attempts = 5
      retry_minimum_backoff          = "10s"
      retry_maximum_backoff          = "300s"
      iam_bindings = [
        { role = "roles/pubsub.subscriber", member = "serviceAccount:worker-sa@my-gcp-project.iam.gserviceaccount.com" }
      ]
    }
  ]
}
```

### Example 2 — Push Subscription to Cloud Run (OIDC Auth)

```hcl
module "pubsub" {
  source     = "../../modules/app_development/Pub_Sub"
  project_id = "my-gcp-project"
  region     = "us-central1"

  topics = [
    { key = "events", name = "application-events" }
  ]

  subscriptions = [
    {
      key          = "events-push"
      name         = "events-push"
      topic_key    = "events"
      push_endpoint = "https://my-cloud-run-svc-xyz-uc.a.run.app/pubsub"
      push_oidc_service_account_email = "pubsub-invoker@my-gcp-project.iam.gserviceaccount.com"
    }
  ]
}
```

### Example 3 — BigQuery Subscription + Avro Schema

```hcl
module "pubsub" {
  source     = "../../modules/app_development/Pub_Sub"
  project_id = "my-gcp-project"
  region     = "us-central1"

  schemas = [
    {
      key        = "telemetry"
      name       = "telemetry-schema"
      type       = "AVRO"
      definition = jsonencode({
        type   = "record"
        name   = "Telemetry"
        fields = [
          { name = "device_id", type = "string" },
          { name = "temperature", type = "float" },
          { name = "timestamp", type = "long" }
        ]
      })
    }
  ]

  topics = [
    {
      key                = "telemetry"
      name               = "telemetry"
      schema_key         = "telemetry"
      schema_encoding    = "BINARY"
    }
  ]

  subscriptions = [
    {
      key                          = "telemetry-bq"
      name                         = "telemetry-bq"
      topic_key                    = "telemetry"
      bigquery_table               = "my-gcp-project.iot_dataset.telemetry_raw"
      bigquery_use_topic_schema    = true
      bigquery_write_metadata      = true
    }
  ]
}
```

---

## Variables — Schemas (`var.schemas[]`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable Terraform map key |
| `create` | `bool` | `true` | Set `false` to skip |
| `name` | `string` | required | Schema resource name |
| `type` | `string` | `"AVRO"` | `"AVRO"` or `"PROTOCOL_BUFFER"` |
| `definition` | `string` | required | Schema definition (JSON for Avro, text for Protobuf) |

---

## Variables — Topics (`var.topics[]`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable Terraform map key |
| `create` | `bool` | `true` | Set `false` to skip |
| `name` | `string` | required | Topic resource name |
| `message_retention_duration` | `string` | `""` | Topic-level retention (e.g. `"86400s"`) |
| `kms_key_name` | `string` | `""` | Cloud KMS key for CMEK encryption |
| `allowed_persistence_regions` | `list(string)` | `[]` | Data residency regions |
| `schema_key` | `string` | `""` | Key of a `var.schemas[]` entry to attach |
| `schema_encoding` | `string` | `"JSON"` | `"JSON"` or `"BINARY"` |
| `iam_bindings` | `list(object)` | `[]` | `{role, member}` IAM bindings on the topic |

---

## Variables — Subscriptions (`var.subscriptions[]`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable Terraform map key |
| `create` | `bool` | `true` | Set `false` to skip |
| `name` | `string` | required | Subscription resource name |
| `topic_key` | `string` | required | Key of the topic in `var.topics[]` |
| `message_retention_duration` | `string` | `"604800s"` | Subscription retention (max `"2678400s"`) |
| `ack_deadline_seconds` | `number` | `20` | Seconds before redelivery (10–600) |
| `retain_acked_messages` | `bool` | `false` | Retain acked messages for replay |
| `expiration_ttl` | `string` | `""` | Subscription inactivity TTL |
| `filter` | `string` | `""` | CEL expression to filter messages |
| `enable_message_ordering` | `bool` | `false` | Require FIFO ordering per `ordering_key` |
| `enable_exactly_once_delivery` | `bool` | `false` | Exactly-once (streaming pull required) |
| `retry_minimum_backoff` | `string` | `"10s"` | Min backoff between redelivery attempts |
| `retry_maximum_backoff` | `string` | `"600s"` | Max backoff between redelivery attempts |
| `dead_letter_key` | `string` | `""` | Enables dead-lettering; names the DLT |
| `dead_letter_max_delivery_attempts` | `number` | `5` | Retries before routing to DLT |
| `push_endpoint` | `string` | `""` | HTTPS endpoint for push delivery |
| `push_attributes` | `map(string)` | `{}` | HTTP attributes sent with push requests |
| `push_oidc_service_account_email` | `string` | `""` | SA for OIDC push auth |
| `push_oidc_audience` | `string` | `""` | OIDC audience (defaults to push_endpoint) |
| `bigquery_table` | `string` | `""` | `project.dataset.table` for BQ subscription |
| `bigquery_use_topic_schema` | `bool` | `false` | Decode using topic schema |
| `bigquery_write_metadata` | `bool` | `false` | Include message metadata columns |
| `bigquery_drop_unknown_fields` | `bool` | `false` | Drop unknown BQ fields |
| `gcs_bucket` | `string` | `""` | GCS bucket name for storage subscription |
| `gcs_filename_prefix` | `string` | `""` | Filename prefix for stored files |
| `gcs_filename_suffix` | `string` | `""` | Filename suffix (e.g. `".json"`) |
| `gcs_max_bytes` | `number` | `0` | Max file size before rotation |
| `gcs_max_duration` | `string` | `""` | Max open duration before writing (e.g. `"300s"`) |
| `gcs_avro_write_metadata` | `bool` | `false` | Include metadata in Avro GCS files |
| `iam_bindings` | `list(object)` | `[]` | `{role, member}` IAM bindings on the subscription |

---

## Outputs

| Output | Description |
|--------|-------------|
| `schema_ids` | Schema IDs, keyed by schema key |
| `topic_ids` | Fully-qualified topic IDs |
| `topic_names` | Topic resource names |
| `dead_letter_topic_ids` | Dead-letter topic IDs |
| `subscription_ids` | Fully-qualified subscription IDs |
| `subscription_names` | Subscription resource names |
| `common_labels` | Merged governance labels |

---

## Notes

- **Pull vs Push**: Use Pull for workers that control their own consumption rate (GKE, Cloud Run with `--no-cpu-throttling`). Use Push for event-driven Cloud Run or Cloud Functions where Pub/Sub triggers the function directly.
- **Dead-letter topics**: Always enable `dead_letter_key` in production to prevent indefinite message redelivery loops from blocking healthy messages.
- **Topic vs subscription retention**: Topic retention enables seek-to-timestamp across all subscriptions; subscription retention is per-consumer and controls replay for that subscriber only.
- **Exactly-once delivery**: Adds per-message cost overhead. Only use when idempotency at the application level is not feasible.
- **BigQuery subscriptions**: The BQ table schema must match the topic schema (or messages must be JSON matching column names). The Pub/Sub service account needs `roles/bigquery.dataEditor` on the dataset.
- **GCS subscriptions**: The Pub/Sub service account needs `roles/storage.objectCreator` on the bucket.
