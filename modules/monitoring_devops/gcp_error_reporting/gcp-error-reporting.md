# Google Cloud Error Reporting

[Cloud Error Reporting](https://cloud.google.com/error-reporting/docs) automatically aggregates, deduplicates, and analyzes application errors from GCP services and user applications. It groups identical stack traces into a single error event, tracks occurrence counts over time, and surfaces new or recurring errors in real time — reducing alert fatigue and accelerating root-cause analysis.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Auto-aggregation** | Groups identical stack traces into a single error group |
| **Deduplication** | Counts unique occurrences; avoids duplicate alerts per event |
| **New error detection** | Fires alerts the first time a previously unseen error appears |
| **Error trends** | Charts error frequency over time per service and version |
| **Source context** | Links stack frames to source code in Cloud Source Repositories |
| **Notification integration** | Sends alerts via Cloud Monitoring notification channels |
| **Multi-language support** | Go, Java, Node.js, Python, Ruby, PHP, .NET |

---

## Core Concepts

### Error Groups

Error Reporting groups errors with identical stack traces (normalized — ignoring line numbers that shift due to minor code changes) into a single **error group**. Each group tracks:

| Field | Description |
|-------|-------------|
| `errorGroupId` | Stable identifier for the group |
| `count` | Total occurrences |
| `firstSeenTime` | When this error was first observed |
| `lastSeenTime` | Most recent occurrence |
| `affectedServices` | Services and versions where the error occurred |
| `representative` | Example error event with full stack trace |

### Error Sources

Error Reporting ingests errors from:

| Source | How Errors Are Captured |
|--------|------------------------|
| **Cloud Logging** | Automatically parses ERROR/CRITICAL log entries with stack traces |
| **Error Reporting API** | Direct write via client libraries |
| **App Engine** | Auto-captured from runtime unhandled exceptions |
| **Cloud Functions** | Auto-captured from unhandled exceptions |
| **Cloud Run** | Captured from stderr output with stack traces |
| **GKE** | Captured via Cloud Logging + agent |

### Enabling Error Reporting

Enable the API:

```hcl
resource "google_project_service" "error_reporting" {
  project = var.project_id
  service = "clouderrorreporting.googleapis.com"

  disable_on_destroy = false
}
```

No additional resource is required — errors are automatically detected from Cloud Logging entries containing stack traces at ERROR severity or above.

### Manual Error Reporting

For programmatic error reporting when the logging-based auto-detection is insufficient:

**Python**

```python
from google.cloud import error_reporting

client = error_reporting.Client(project="my-project", service="my-service", version="1.0.0")

try:
    result = 1 / 0
except ZeroDivisionError:
    client.report_exception()  # reports current exception with stack trace
```

**Go**

```go
import "cloud.google.com/go/errorreporting"

errClient, _ := errorreporting.NewClient(ctx, "my-project", errorreporting.Config{
    ServiceName:    "my-service",
    ServiceVersion: "1.0.0",
})
defer errClient.Close()

errClient.Report(errorreporting.Entry{
    Error: err,
    Req:   r,   // optional: associate with HTTP request
})
```

**Structured Log Entry (any language)**

Write a structured log entry at ERROR severity with a `stack_trace` field — Error Reporting picks it up automatically:

```json
{
  "severity": "ERROR",
  "message": "NullPointerException in PaymentService",
  "stack_trace": "java.lang.NullPointerException\n\tat com.example.PaymentService.process(PaymentService.java:42)\n\tat ...",
  "serviceContext": {
    "service": "payment-service",
    "version": "2.1.0"
  }
}
```

### Alerting on New Errors

Set up a Cloud Monitoring alerting policy to fire when a new error group is detected:

```hcl
resource "google_monitoring_alert_policy" "new_errors" {
  display_name = "New application error detected"
  combiner     = "OR"

  conditions {
    display_name = "Error Reporting new error group"
    condition_threshold {
      filter          = "metric.type=\"clouderrorreporting.googleapis.com/errorgroup/count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.name]
}
```

### Resolving and Ignoring Errors

Errors can be **resolved** (marked as fixed; re-opens if seen again) or **muted** via the Console or API:

```bash
# Resolve an error group via gcloud
gcloud beta error-reporting events delete --group-id=GROUP_ID --project=my-project
```

---

## IAM Roles

| Role | Capability |
|------|-----------|
| `roles/errorreporting.writer` | Write error events (application SAs) |
| `roles/errorreporting.viewer` | View errors in the console |
| `roles/errorreporting.admin` | View, resolve, and delete error groups |

```hcl
resource "google_project_iam_member" "error_writer" {
  project = var.project_id
  role    = "roles/errorreporting.writer"
  member  = "serviceAccount:${google_service_account.app.email}"
}
```

---

## Security Guidance

- Restrict `roles/errorreporting.viewer` to engineering and on-call teams — stack traces may contain internal logic details.
- Avoid logging PII or secrets in error messages or stack trace context; sanitize exception messages before they reach logs.
- Use **structured log entries** with `serviceContext.service` and `serviceContext.version` to keep error groups separated per service version.
- Set **alerting policies** on error count increase rate to catch regression spikes after deployments.
- Correlate Error Reporting groups with Cloud Trace by including `traceId` in log entries for full request context.

---

## Related Docs

- [Cloud Error Reporting Overview](https://cloud.google.com/error-reporting/docs/overview)
- [Setting Up Error Reporting](https://cloud.google.com/error-reporting/docs/setup)
- [Error Reporting API](https://cloud.google.com/error-reporting/reference/rest)
- [Pricing](https://cloud.google.com/stackdriver/pricing#error-reporting)
- [google_project_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service)
