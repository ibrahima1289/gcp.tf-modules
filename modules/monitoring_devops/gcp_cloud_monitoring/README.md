# GCP Cloud Monitoring Terraform Module

Reusable Terraform module for creating [Google Cloud Monitoring](https://cloud.google.com/monitoring/docs) resources: notification channels, alert policies (threshold, absent, log-based), uptime checks (HTTP/S and TCP), and dashboards. Supports creating multiple of each resource type from a single module call.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "gcp_cloud_monitoring"
├── google_monitoring_notification_channel.channel    (one per notification_channels[])
│   └── dynamic sensitive_labels {}                  (when auth_token / password / service_key is set)
│
├── google_monitoring_alert_policy.policy             (one per alert_policies[])
│   ├── notification_channels → channel.name refs    (resolved from notification_channel_keys[])
│   ├── dynamic conditions {}                        (one per conditions[])
│   │   ├── dynamic condition_threshold {}           (when condition_threshold != null)
│   │   │   └── dynamic aggregations {}              (one per aggregations[])
│   │   ├── dynamic condition_absent {}              (when condition_absent != null)
│   │   │   └── dynamic aggregations {}
│   │   └── dynamic condition_matched_log {}         (when condition_matched_log != null)
│   ├── dynamic documentation {}                     (when documentation_content != "")
│   └── dynamic alert_strategy {}                    (when alert_strategy != null)
│
├── google_monitoring_uptime_check_config.uptime_check (one per uptime_checks[])
│   ├── dynamic http_check {}                        (when http_check != null)
│   │   └── dynamic accepted_response_status_codes {}
│   ├── dynamic tcp_check {}                         (when tcp_check != null)
│   ├── dynamic monitored_resource {}                (when monitored_resource != null)
│   ├── dynamic resource_group {}                    (when resource_group != null)
│   └── dynamic content_matchers {}                  (one per content_matchers[])
│
└── google_monitoring_dashboard.dashboard            (one per dashboards[])
```

Data flow:

```text
var.notification_channels[] + var.alert_policies[] + var.uptime_checks[] + var.dashboards[]
        ↓
locals: channels_map / alert_policies_map / uptime_checks_map / dashboards_map
        (create = false entries excluded)
        ↓
google_monitoring_notification_channel  ←── referenced by name in alert_policy.notification_channels
google_monitoring_alert_policy
google_monitoring_uptime_check_config
google_monitoring_dashboard
        ↓
outputs: channel names/ids, policy names/ids, uptime_check_ids, dashboard_ids, common_labels
```

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |

---

## Resources Created

| Resource | Description |
|----------|-------------|
| [`google_monitoring_notification_channel`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel) | Delivery endpoint for alert notifications (email, Slack, PagerDuty, Pub/Sub, webhook) |
| [`google_monitoring_alert_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | Alert policy with threshold, absent, or log-based conditions |
| [`google_monitoring_uptime_check_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config) | Periodic HTTP/S or TCP probe from GCP's global checker network |
| [`google_monitoring_dashboard`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard) | Cloud Monitoring dashboard (raw JSON definition) |

---

## Variables

### Top-level (required)

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | GCP project ID for all Cloud Monitoring resources |

### Top-level (optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Provider region (Cloud Monitoring is global) |
| `tags` | `map(string)` | `{}` | Governance labels merged into all resources |
| `notification_channels` | `list(object)` | `[]` | Notification channel definitions |
| `alert_policies` | `list(object)` | `[]` | Alert policy definitions |
| `uptime_checks` | `list(object)` | `[]` | Uptime check definitions |
| `dashboards` | `list(object)` | `[]` | Dashboard JSON definitions |

---

### `notification_channels[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable key for `for_each` |
| `display_name` | `string` | required | Human-readable channel name |
| `type` | `string` | required | `email` · `slack` · `pagerduty` · `pubsub` · `webhook_tokenauth` · `sms` · `google_chat` |
| `labels` | `map(string)` | `{}` | Type-specific config (e.g. `{ email_address = "..." }` or `{ channel_name = "#ops" }`) |
| `sensitive_labels.auth_token` | `string` | `""` | Slack or webhook auth token |
| `sensitive_labels.password` | `string` | `""` | Basic auth password |
| `sensitive_labels.service_key` | `string` | `""` | PagerDuty service/integration key |
| `enabled` | `bool` | `true` | Enable or disable the channel |
| `user_labels` | `map(string)` | `{}` | Additional resource labels |
| `create` | `bool` | `true` | Set `false` to skip without removing from config |

### `alert_policies[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable key for `for_each` |
| `display_name` | `string` | required | Policy name shown in the Cloud Console |
| `combiner` | `string` | `OR` | `OR` · `AND` · `AND_WITH_MATCHING_RESOURCE` |
| `enabled` | `bool` | `true` | Enable or disable the policy |
| `notification_channel_keys` | `list(string)` | `[]` | Keys from `notification_channels[]` to notify |
| `documentation_content` | `string` | `""` | Markdown run-book text shown in alert detail pane |
| `conditions` | `list(object)` | required | One or more alert conditions (see below) |
| `alert_strategy.auto_close` | `string` | `604800s` | Seconds until open incidents auto-close |
| `alert_strategy.notification_rate_limit.period` | `string` | `3600s` | Min time between repeat notifications |
| `labels` | `map(string)` | `{}` | Additional user labels |
| `create` | `bool` | `true` | Set `false` to skip without removing from config |

### `conditions[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `display_name` | `string` | required | Condition name |
| `condition_threshold` | `object` | `null` | Fires when a metric crosses a numeric threshold |
| `condition_threshold.filter` | `string` | required | MQL/resource filter selecting the time series |
| `condition_threshold.duration` | `string` | `60s` | Violation persistence window before firing |
| `condition_threshold.comparison` | `string` | `COMPARISON_GT` | `COMPARISON_GT` · `COMPARISON_LT` · `COMPARISON_GE` · `COMPARISON_LE` · `COMPARISON_EQ` · `COMPARISON_NE` |
| `condition_threshold.threshold_value` | `number` | `0` | Numeric threshold value |
| `condition_threshold.aggregations[].alignment_period` | `string` | `60s` | Alignment period for the aggregation window |
| `condition_threshold.aggregations[].per_series_aligner` | `string` | `ALIGN_MEAN` | `ALIGN_MEAN` · `ALIGN_MAX` · `ALIGN_MIN` · `ALIGN_SUM` · `ALIGN_COUNT` · `ALIGN_RATE` |
| `condition_threshold.aggregations[].cross_series_reducer` | `string` | `""` | `REDUCE_MEAN` · `REDUCE_MAX` · `REDUCE_SUM` · `REDUCE_COUNT`; empty = no reduction |
| `condition_threshold.aggregations[].group_by_fields` | `list(string)` | `[]` | Resource or metric label fields to group by |
| `condition_absent` | `object` | `null` | Fires when time series data goes missing |
| `condition_absent.filter` | `string` | required | Filter identifying the expected time series |
| `condition_absent.duration` | `string` | `300s` | How long data must be absent before firing |
| `condition_matched_log` | `object` | `null` | Fires on each matching structured log entry |
| `condition_matched_log.filter` | `string` | required | Cloud Logging filter expression |
| `condition_matched_log.label_extractors` | `map(string)` | `{}` | Extract label values from log entries |

### `uptime_checks[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable key |
| `display_name` | `string` | required | Human-readable check name |
| `timeout` | `string` | `10s` | Max time to wait for a response |
| `period` | `string` | `60s` | Probe frequency: `60s` · `300s` · `600s` · `900s` · `1800s` · `3600s` |
| `checker_type` | `string` | `STATIC_IP_CHECKERS` | `STATIC_IP_CHECKERS` or `VPC_CHECKERS` |
| `selected_regions` | `list(string)` | `[]` | Restrict to `USA` · `EUROPE` · `ASIA_PACIFIC`; empty = all regions |
| `http_check.path` | `string` | `/` | URL path to probe |
| `http_check.port` | `number` | `443` | TCP port |
| `http_check.use_ssl` | `bool` | `true` | Use HTTPS |
| `http_check.validate_ssl` | `bool` | `true` | Validate the SSL certificate |
| `http_check.request_method` | `string` | `GET` | `GET` or `POST` |
| `http_check.headers` | `map(string)` | `{}` | Custom request headers |
| `http_check.accepted_response_status_codes` | `list(object)` | `[]` | Success status codes; empty = accept 2xx |
| `tcp_check.port` | `number` | required | TCP port to probe |
| `monitored_resource.type` | `string` | required | `uptime_url` · `gce_instance` · `gae_app` |
| `monitored_resource.labels` | `map(string)` | required | Resource labels (e.g. `{ host = "example.com" }`) |
| `content_matchers[].content` | `string` | required | String to match in the response body |
| `content_matchers[].matcher` | `string` | `CONTAINS_STRING` | `CONTAINS_STRING` · `NOT_CONTAINS_STRING` · `MATCHES_REGEX` |
| `create` | `bool` | `true` | Set `false` to skip |

### `dashboards[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable key |
| `dashboard_json` | `string` | required | Complete JSON dashboard definition (export from the Cloud Monitoring console) |
| `create` | `bool` | `true` | Set `false` to skip |

---

## Outputs

| Output | Description |
|--------|-------------|
| `notification_channel_ids` | Channel resource IDs keyed by channel key |
| `notification_channel_names` | Channel resource names (full path) for use in external alert policies |
| `alert_policy_ids` | Alert policy resource IDs keyed by policy key |
| `alert_policy_names` | Alert policy resource names keyed by policy key |
| `uptime_check_ids` | Uptime check resource IDs keyed by check key |
| `uptime_check_names` | Uptime check resource names keyed by check key |
| `uptime_check_uptime_check_ids` | Short uptime check IDs for use in metric filters |
| `dashboard_ids` | Dashboard resource IDs keyed by dashboard key |
| `common_labels` | Merged governance labels applied by this module |

---

## Usage

```hcl
module "gcp_cloud_monitoring" {
  source = "../../modules/monitoring_devops/gcp_cloud_monitoring"

  project_id = "my-project-id"
  region     = "us-central1"

  tags = {
    environment = "production"
    team        = "platform"
  }

  # ── Notification Channels ──────────────────────────────────────────────────
  notification_channels = [
    {
      key          = "ops-email"
      display_name = "Ops Team Email"
      type         = "email"
      labels       = { email_address = "ops@example.com" }
    },
    {
      key          = "ops-slack"
      display_name = "Ops Slack #alerts"
      type         = "slack"
      labels       = { channel_name = "#alerts" }
      sensitive_labels = {
        auth_token  = var.slack_auth_token
        password    = ""
        service_key = ""
      }
    },
  ]

  # ── Alert Policies ─────────────────────────────────────────────────────────
  alert_policies = [
    {
      key          = "high-cpu"
      display_name = "GCE CPU > 80% for 5 min"
      combiner     = "OR"
      notification_channel_keys = ["ops-email", "ops-slack"]

      documentation_content = <<-MD
        ## High CPU Alert
        Instance CPU utilization exceeded 80% for 5 minutes.
        **Action**: Check running processes with `top` or `htop`.
      MD

      conditions = [
        {
          display_name = "CPU utilization > 0.8"
          condition_threshold = {
            filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
            duration        = "300s"
            comparison      = "COMPARISON_GT"
            threshold_value = 0.8
            aggregations = [
              {
                alignment_period     = "60s"
                per_series_aligner   = "ALIGN_MEAN"
                cross_series_reducer = "REDUCE_MEAN"
                group_by_fields      = ["resource.labels.instance_id"]
              }
            ]
          }
        }
      ]

      alert_strategy = {
        auto_close = "86400s"   # 1 day
        notification_rate_limit = { period = "3600s" }
      }
    },
  ]

  # ── Uptime Checks ───────────────────────────────────────────────────────────
  uptime_checks = [
    {
      key          = "api-health"
      display_name = "API /health HTTPS Check"
      timeout      = "10s"
      period       = "60s"

      http_check = {
        path         = "/health"
        port         = 443
        use_ssl      = true
        validate_ssl = true
      }

      monitored_resource = {
        type   = "uptime_url"
        labels = { host = "api.example.com" }
      }

      content_matchers = [
        { content = "\"status\":\"ok\"", matcher = "CONTAINS_STRING" }
      ]
    },
  ]

  # ── Dashboards ──────────────────────────────────────────────────────────────
  dashboards = [
    {
      key = "app-overview"
      dashboard_json = jsonencode({
        displayName = "App Overview"
        gridLayout = {
          columns = "2"
          widgets = []
        }
      })
    },
  ]
}
```

### Referencing channels outside this module

Use `notification_channel_names` to wire channels into alert policies managed elsewhere:

```hcl
resource "google_monitoring_alert_policy" "external_policy" {
  display_name          = "External Alert"
  combiner              = "OR"
  notification_channels = values(module.gcp_cloud_monitoring.notification_channel_names)
  # ...
}
```

---

## Related Docs

- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Cloud Monitoring Explainer](gcp-cloud-monitoring.md)
- [Cloud Monitoring Deployment Plan](../../../tf-plans/gcp_cloud_monitoring/README.md)
- [Cloud Monitoring Pricing](https://cloud.google.com/monitoring/pricing)
- [Alert Policy Conditions](https://cloud.google.com/monitoring/alerts/types-of-conditions)
- [Notification Channel Types](https://cloud.google.com/monitoring/support/notification-options)
- [google_monitoring_notification_channel](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel)
- [google_monitoring_alert_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy)
- [google_monitoring_uptime_check_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config)
- [google_monitoring_dashboard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard)
