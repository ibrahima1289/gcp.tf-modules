# Google Cloud Monitoring

[Cloud Monitoring](https://cloud.google.com/monitoring/docs) is the observability backbone of Google Cloud, providing metrics collection, dashboards, alerting, uptime checks, and SLO tracking across GCP resources, hybrid environments, and custom applications. It is part of the **Google Cloud Observability** suite (formerly Stackdriver) alongside Cloud Logging, Trace, and Profiler.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Cloud Monitoring ingests time-series metrics from GCP services automatically (system metrics) and from user-defined instrumentation (custom metrics). All data is stored in a **Workspace** (scoping project) that aggregates metrics from multiple GCP projects, enabling cross-project dashboards and alerts from a single pane of glass.

| Capability | Description |
|------------|-------------|
| **System metrics** | Automatically collected from Compute, GKE, Cloud SQL, Cloud Run, etc. |
| **Custom metrics** | User-defined metrics written via the Monitoring API, OpenTelemetry, or agent |
| **Alerting policies** | Threshold, absence, and rate-of-change conditions with multi-channel notifications |
| **Dashboards** | Drag-and-drop charts for time-series, heatmaps, scoreboards, and tables |
| **Uptime checks** | HTTP/HTTPS/TCP/gRPC checks from global PoPs; feeds into alerting |
| **SLOs** | Service Level Objectives with error budget tracking and burn-rate alerting |
| **Metric scopes** | Aggregate metrics from multiple projects into one scoping project |
| **Log-based metrics** | Convert log entries into numeric metrics for alerting |

---

## Core Concepts

### Metric Types

| Category | Prefix | Examples |
|----------|--------|---------|
| **GCP system metrics** | `compute.googleapis.com/` | `instance/cpu/utilization`, `instance/disk/read_bytes_count` |
| **Kubernetes metrics** | `kubernetes.io/` | `container/cpu/core_usage_time`, `pod/volume/used_bytes` |
| **Custom metrics** | `custom.googleapis.com/` | User-defined counters, gauges, distributions |
| **External metrics** | `external.googleapis.com/` | Prometheus-scraped, Datadog-bridged metrics |
| **Log-based metrics** | `logging.googleapis.com/user/` | Derived from log filter matches |

### Alerting Policies

An alerting policy combines one or more **conditions** with **notification channels** and a **documentation** block.

```hcl
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "VM CPU > 80%"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "CPU utilization above 80%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content   = "CPU has exceeded 80% for 60 seconds. Review instance workload."
    mime_type = "text/markdown"
  }
}
```

### Notification Channels

| Type | Terraform Resource |
|------|--------------------|
| Email | `google_monitoring_notification_channel` (`type = "email"`) |
| PagerDuty | `google_monitoring_notification_channel` (`type = "pagerduty"`) |
| Pub/Sub | `google_monitoring_notification_channel` (`type = "pubsub"`) |
| Slack | `google_monitoring_notification_channel` (`type = "slack"`) |
| Webhooks | `google_monitoring_notification_channel` (`type = "webhook_tokenauth"`) |

```hcl
resource "google_monitoring_notification_channel" "email" {
  display_name = "Ops Team Email"
  type         = "email"
  labels = {
    email_address = "ops-team@example.com"
  }
}
```

### Dashboards

```hcl
resource "google_monitoring_dashboard" "overview" {
  dashboard_json = jsonencode({
    displayName = "Application Overview"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "Request Rate"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"run.googleapis.com/request_count\""
                  aggregation = { perSeriesAligner = "ALIGN_RATE" }
                }
              }
            }]
          }
        }
      ]
    }
  })
}
```

### Uptime Checks

```hcl
resource "google_monitoring_uptime_check_config" "https_check" {
  display_name = "API health check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "api.example.com"
    }
  }
}
```

### SLOs

```hcl
resource "google_monitoring_service" "app" {
  service_id   = "my-app"
  display_name = "My Application"
  basic_service {
    service_type   = "CLOUD_RUN"
    service_labels = { service_name = "my-app", location = "us-central1" }
  }
}

resource "google_monitoring_slo" "availability" {
  service      = google_monitoring_service.app.service_id
  slo_id       = "availability-slo"
  display_name = "99.9% Availability SLO"
  goal         = 0.999
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio {
      good_service_filter  = "metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"2xx\""
      total_service_filter = "metric.type=\"run.googleapis.com/request_count\""
    }
  }
}
```

### Log-Based Metrics

Convert log entries into metrics for alerting on events not captured by system metrics:

```hcl
resource "google_logging_metric" "error_count" {
  name        = "application-errors"
  description = "Count of ERROR severity log entries from the application"
  filter      = "severity=ERROR AND resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"my-app\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "error_type"
      value_type  = "STRING"
      description = "Error classification label"
    }
  }

  label_extractors = {
    error_type = "EXTRACT(jsonPayload.error_type)"
  }
}
```

---

## Metric Retention

| Data type | Retention |
|-----------|-----------|
| System metrics (raw) | 6 weeks |
| System metrics (reduced granularity) | 6 months |
| Custom metrics | 6 weeks |
| Log-based metrics | 6 weeks |

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_monitoring_alert_policy` | Create alerting policies with conditions and channels |
| `google_monitoring_notification_channel` | Define notification destinations |
| `google_monitoring_dashboard` | Create monitoring dashboards (JSON payload) |
| `google_monitoring_uptime_check_config` | HTTP/TCP uptime checks from global PoPs |
| `google_monitoring_service` | Define a monitored service for SLO tracking |
| `google_monitoring_slo` | Define SLOs with error budget and burn-rate alerts |
| `google_monitoring_metric_descriptor` | Register custom metric types |
| `google_monitoring_group` | Group monitored resources dynamically by filter |
| `google_logging_metric` | Create log-based metrics for alerting |

---

## Security Guidance

- Grant `roles/monitoring.editor` to automation SAs; `roles/monitoring.viewer` to read-only dashboards; avoid `roles/monitoring.admin` in production.
- Route alert notifications through **Pub/Sub** for audit trail and programmatic processing rather than email-only.
- Use **log-based metrics** to alert on security-relevant log patterns (e.g., IAM policy changes, failed auth attempts).
- Enable **metric scopes** to centralize multi-project monitoring into a single security-team workspace.
- Store sensitive dashboard configs (API keys in webhook channels) in **Secret Manager** and reference via `sensitive = true` variables.
- Set **alerting policies** on quota usage (> 80%) to catch runaway workloads before they hit limits.

---

## Related Docs

- [Cloud Monitoring Overview](https://cloud.google.com/monitoring/docs/overview)
- [Alerting Policies](https://cloud.google.com/monitoring/alerts)
- [SLO Monitoring](https://cloud.google.com/monitoring/slo-monitoring)
- [Uptime Checks](https://cloud.google.com/monitoring/uptime-checks)
- [Pricing](https://cloud.google.com/stackdriver/pricing)
- [google_monitoring_alert_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy)
- [google_monitoring_dashboard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard)
- [google_monitoring_slo](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_slo)
