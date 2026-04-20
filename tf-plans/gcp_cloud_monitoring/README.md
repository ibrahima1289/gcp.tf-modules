# GCP Cloud Monitoring Deployment Plan

Wrapper configuration for the [GCP Cloud Monitoring module](../../modules/monitoring_devops/gcp_cloud_monitoring/README.md). Deploys notification channels, alert policies (threshold, absent, log-based), uptime checks, and dashboards for a Google Cloud project.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_cloud_monitoring/
├── providers.tf      → GCS backend (optional) + google provider
├── variables.tf      → project_id, region, tags, and the four resource lists
├── locals.tf         → created_date
├── main.tf           → module "gcp_cloud_monitoring" call
├── outputs.tf        → pass-through outputs from module
├── terraform.tfvars  → example values for all resource types
└── README.md         → this file
        ↓
modules/monitoring_devops/gcp_cloud_monitoring/
├── google_monitoring_notification_channel  (one per notification_channels[])
├── google_monitoring_alert_policy          (one per alert_policies[])
├── google_monitoring_uptime_check_config   (one per uptime_checks[])
└── google_monitoring_dashboard             (one per dashboards[])
```

### Resource Relationships

```text
notification_channels[key] ──► alert_policies[].notification_channel_keys[key]
                                     │
                     fires ◄── conditions: threshold | absent | log-based
                                     │
                              alert_strategy: auto_close, rate_limit
```

---

## Prerequisites

- GCP project with the following APIs enabled:
  - `monitoring.googleapis.com` (Cloud Monitoring)
  - `logging.googleapis.com` (required for log-based conditions)
- Terraform `>= 1.5` and Google provider `>= 6.0`
- IAM role: `roles/monitoring.admin` on the project
- For Slack/PagerDuty channels: service credentials stored in [Secret Manager](https://cloud.google.com/secret-manager/docs)

---

## Apply Workflow

```bash
# 1. Authenticate
gcloud auth application-default login --no-launch-browser

# 2. Set project
gcloud config set project my-project-id

# 3. Enable required APIs
gcloud services enable monitoring.googleapis.com logging.googleapis.com \
  --project=my-project-id

# 4. Configure terraform.tfvars with your project_id and resource definitions

# 5. Initialize
terraform init

# 6. Review
terraform plan -out=tfplan

# 7. Apply
terraform apply tfplan

# 8. Inspect outputs
terraform output notification_channel_names
terraform output alert_policy_names
terraform output uptime_check_uptime_check_ids
```

> **Destroy note**: Deleting notification channels will remove them from all alert policies. Set `create = false` on individual resources to deactivate without removing from config.

---

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|:--------:|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID |
| `region` | `string` | ➖ | `us-central1` | Provider region |
| `tags` | `map(string)` | ➖ | `{}` | Governance labels |
| `notification_channels` | `list(object)` | ➖ | `[]` | Notification channel definitions |
| `alert_policies` | `list(object)` | ➖ | `[]` | Alert policy definitions |
| `uptime_checks` | `list(object)` | ➖ | `[]` | Uptime check definitions |
| `dashboards` | `list(object)` | ➖ | `[]` | Dashboard JSON definitions |

See [module variables](../../modules/monitoring_devops/gcp_cloud_monitoring/README.md#variables) for the full field reference.

---

## Outputs

| Output | Description |
|--------|-------------|
| `notification_channel_ids` | Channel IDs keyed by channel key |
| `notification_channel_names` | Channel full resource names (use in external alert policies) |
| `alert_policy_ids` | Policy IDs keyed by policy key |
| `alert_policy_names` | Policy resource names |
| `uptime_check_ids` | Check IDs keyed by check key |
| `uptime_check_names` | Check resource names |
| `uptime_check_uptime_check_ids` | Short check IDs for use in metric filters |
| `dashboard_ids` | Dashboard IDs keyed by dashboard key |
| `common_labels` | Merged governance labels applied by this call |

---

## Configuration Examples

### Notification Channel Types

| Type | Required `labels` key | Sensitive key |
|------|-----------------------|---------------|
| `email` | `email_address` | — |
| `slack` | `channel_name` | `auth_token` |
| `pagerduty` | `channel_name` | `service_key` |
| `pubsub` | `topic` | — |
| `webhook_tokenauth` | `url` | `auth_token` |
| `sms` | `number` | — |

### Condition Types

| Type | Key in `conditions[]` | Use case |
|------|----------------------|----------|
| Metric threshold | `condition_threshold` | CPU > 80%, latency > 2s |
| Data absent | `condition_absent` | Instance stopped reporting metrics |
| Log-based | `condition_matched_log` | ERROR/CRITICAL log entries |

### Common Metric Filters

```hcl
# GCE CPU utilization
"metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""

# Cloud Run request latency (p99)
"metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\""

# Cloud SQL CPU utilization
"metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" resource.type=\"cloudsql_database\""

# GCS request count
"metric.type=\"storage.googleapis.com/api/request_count\" resource.type=\"gcs_bucket\""

# Pub/Sub undelivered message count
"metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\""

# Uptime check passed (reference check by ID)
"metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" metric.label.check_id=\"<uptime_check_id>\""
```

### Exporting a Dashboard JSON

1. Open [Cloud Monitoring → Dashboards](https://console.cloud.google.com/monitoring/dashboards)
2. Select the dashboard
3. Click **⋮ (More options) → Download JSON**
4. Paste the JSON into `dashboard_json` using a heredoc:

```hcl
dashboards = [
  {
    key            = "my-dashboard"
    dashboard_json = <<-JSON
      { ... }
    JSON
  }
]
```

---

## Related Docs

- [GCP Cloud Monitoring Module](../../modules/monitoring_devops/gcp_cloud_monitoring/README.md)
- [Cloud Monitoring Explainer](../../modules/monitoring_devops/gcp_cloud_monitoring/gcp-cloud-monitoring.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Alert Policy Conditions](https://cloud.google.com/monitoring/alerts/types-of-conditions)
- [Notification Channel Types](https://cloud.google.com/monitoring/support/notification-options)
- [Uptime Check Docs](https://cloud.google.com/monitoring/uptime-checks)
- [Dashboard JSON Reference](https://cloud.google.com/monitoring/api/ref_v3/rest/v1/projects.dashboards)
- [Cloud Monitoring Pricing](https://cloud.google.com/monitoring/pricing)
