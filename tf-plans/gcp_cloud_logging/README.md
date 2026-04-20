# GCP Cloud Logging — Deployment Plan

> Module: [modules/monitoring_devops/gcp_cloud_logging](../../modules/monitoring_devops/gcp_cloud_logging/README.md)
> Back to: [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

This deployment plan wires the `gcp_cloud_logging` module to real GCP project values. Edit `terraform.tfvars` to configure log buckets, sinks, exclusions, and log-based metrics, then run the standard Terraform workflow.

---

## File Structure

```text
tf-plans/gcp_cloud_logging/
├── main.tf           # module call with all four resource lists
├── variables.tf      # mirrors module variable definitions
├── locals.tf         # created_date timestamp
├── outputs.tf        # pass-through module outputs
├── providers.tf      # Google provider + optional GCS backend
├── terraform.tfvars  # example values — customize before applying
└── README.md         # this file
```

---

## Prerequisites

1. **Terraform** `>= 1.5` installed locally or in CI.
2. A GCP project with **Cloud Logging API** enabled (`logging.googleapis.com`).
3. Caller must have `roles/logging.admin` on the project (or a custom role with equivalent permissions).
4. For **BigQuery sinks**: create the dataset before applying; grant the sink's `writer_identity` `roles/bigquery.dataEditor` on the dataset after the first apply.
5. For **GCS sinks**: the bucket must exist; grant `roles/storage.objectCreator` to the sink's `writer_identity`.
6. For **Pub/Sub sinks**: the topic must exist; grant `roles/pubsub.publisher` to the sink's `writer_identity`.

---

## Apply Workflow

```bash
cd tf-plans/gcp_cloud_logging

# 1. Authenticate
gcloud auth application-default login

# 2. Initialise providers and backend
terraform init

# 3. Review planned changes
terraform plan -var-file=terraform.tfvars

# 4. Apply
terraform apply -var-file=terraform.tfvars

# 5. Grant sink writer identities on their destinations (one-time)
terraform output log_sink_writer_identities
```

---

## Sink Destination URI Formats

| Destination | URI Format |
|-------------|-----------|
| Cloud Storage | `storage.googleapis.com/<bucket-name>` |
| BigQuery | `bigquery.googleapis.com/projects/<project>/datasets/<dataset>` |
| Pub/Sub | `pubsub.googleapis.com/projects/<project>/topics/<topic>` |
| Log Bucket (this project) | `logging.googleapis.com/projects/<project>/locations/<location>/buckets/<bucket-id>` |
| Log Bucket (other project) | `logging.googleapis.com/projects/<other-project>/locations/<location>/buckets/<bucket-id>` |

---

## Sink IAM After Apply

The `log_sink_writer_identities` output returns a service account per sink. Grant it the required role on the destination:

```hcl
# Example: grant GCS archival sink write access
resource "google_storage_bucket_iam_member" "errors_sink_writer" {
  bucket = "main-project-log-archive"
  role   = "roles/storage.objectCreator"
  member = module.gcp_cloud_logging.log_sink_writer_identities["errors-to-gcs"]
}

# Example: grant BigQuery audit sink write access
resource "google_bigquery_dataset_iam_member" "audit_sink_writer" {
  dataset_id = "audit_logs"
  role       = "roles/bigquery.dataEditor"
  member     = module.gcp_cloud_logging.log_sink_writer_identities["audit-to-bq"]
}
```

---

## Log-Based Metric Filter Examples

| Use Case | Filter |
|----------|--------|
| IAM policy changes | `protoPayload.methodName="SetIamPolicy"` |
| HTTP 5xx errors | `httpRequest.status>=500 httpRequest.status<600` |
| Cloud SQL errors | `resource.type="cloudsql_database" severity>=ERROR` |
| GKE pod crashes | `resource.type="k8s_container" jsonPayload.message:"OOMKilled"` |
| Secret Manager access | `protoPayload.serviceName="secretmanager.googleapis.com" protoPayload.methodName:"AccessSecretVersion"` |
| Org policy denials | `protoPayload.status.code=7 protoPayload.authorizationInfo.granted=false` |

---

## Log Bucket Retention Reference

| Bucket | Default Retention | Min | Max | Configurable |
|--------|------------------|-----|-----|-------------|
| `_Required` (Admin Activity, System Event) | 400 days | 400 days | — | ❌ |
| `_Default` (all other logs) | 30 days | 1 day | 3650 days | ✅ |
| Custom buckets | User-defined | 1 day | 3650 days | ✅ |

---

## Related Docs

- [Cloud Logging Module](../../modules/monitoring_devops/gcp_cloud_logging/README.md)
- [Cloud Logging Explainer](../../modules/monitoring_devops/gcp_cloud_logging/gcp-cloud-logging.md)
- [Cloud Monitoring Module](../../modules/monitoring_devops/gcp_cloud_monitoring/README.md)
- [Cloud Monitoring Deployment Plan](../gcp_cloud_monitoring/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Cloud Logging Pricing](https://cloud.google.com/stackdriver/pricing)
- [Log Router & Sinks](https://cloud.google.com/logging/docs/export/configure_export_v2)
- [Log Analytics](https://cloud.google.com/logging/docs/log-analytics)
