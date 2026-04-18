# GCP Quotas

[Cloud Quotas](https://cloud.google.com/docs/quota) are system-enforced limits on how much of a particular GCP resource a project or organization can consume. Quotas protect the shared infrastructure from abuse and runaway usage, and they are surfaced through the **Cloud Quotas API** (v1) and the legacy Service Usage API. Terraform can read quota information and submit **quota adjustment requests** using `google_cloud_quotas_quota_preference`.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Every GCP project inherits a default quota for each API. When a workload exceeds a quota the API returns an `HTTP 429 RESOURCE_EXHAUSTED` error. Quotas operate at two scopes:

| Scope | Description |
|-------|-------------|
| **Project-level** | Limits for a single project (most quotas) |
| **Region / Zone-level** | Sub-quotas within a project for regional resources (e.g., CPUs per region) |
| **Organization-level** | Aggregated limits across all projects under an org (less common) |

---

## Core Concepts

### Quota Dimensions

Each quota has:

| Field | Description |
|-------|-------------|
| **Service** | The GCP API (e.g., `compute.googleapis.com`) |
| **Metric** | Specific resource being measured (e.g., `compute.googleapis.com/cpus`) |
| **Limit ID** | Named limit within the metric (e.g., `CPUS-per-project-region`) |
| **Dimensions** | Scoping key-value pairs (`region`, `zone`, etc.) |
| **Quota value** | Numeric ceiling (could be count, bytes, requests/s) |

### Reading Quotas

Use the `gcloud` CLI to inspect current quotas and usage:

```bash
# List all quotas for a project
gcloud quotas info list --project=my-project --service=compute.googleapis.com

# Check a specific quota
gcloud quotas info describe \
  --project=my-project \
  --service=compute.googleapis.com \
  --quota-id=CPUS-per-project-region \
  --dimensions=region=us-central1
```

### Quota Preferences (Adjustment Requests)

A **quota preference** is a formal request to change a quota limit. Google reviews most requests automatically within minutes to hours; some require manual review.

```hcl
resource "google_cloud_quotas_quota_preference" "cpus_us_central1" {
  project      = "my-project"
  name         = "projects/my-project/locations/global/quotaPreferences/compute-cpus-us-central1"
  service      = "compute.googleapis.com"
  quota_id     = "CPUS-per-project-region"
  contact_email = "infra-team@example.com"

  quota_config {
    preferred_value = 500
    dimensions = {
      region = "us-central1"
    }
  }

  justification = "Planned scale-out to 500 n2-standard-4 nodes for batch workload Q3 2026"
}
```

### Quota Override (Legacy — Admin Only)

Organization admins can grant a project a temporary override via the Service Usage API:

```hcl
resource "google_service_usage_consumer_quota_override" "cpu_override" {
  project        = "my-project"
  service        = "compute.googleapis.com"
  metric         = "compute.googleapis.com/cpus"
  limit          = "/project/region"
  override_value = "500"
  dimensions = {
    region = "us-central1"
  }
}
```

> Prefer `google_cloud_quotas_quota_preference` (v1 API) over `google_service_usage_consumer_quota_override` for new implementations.

---

## Common Quotas to Monitor

| Service | Metric | Common Limit |
|---------|--------|-------------|
| Compute Engine | `compute.googleapis.com/cpus` | CPUs per region |
| Compute Engine | `compute.googleapis.com/global_in_use_addresses` | Global external IPs |
| Cloud Storage | `storage.googleapis.com/default_requests` | API requests/day |
| Cloud Run | `run.googleapis.com/requests` | Concurrent requests |
| IAM | `iam.googleapis.com/quota/service-account-count` | Service accounts per project |
| GKE | `container.googleapis.com/node_pools` | Node pools per cluster |
| BigQuery | `bigquery.googleapis.com/quota/query/usage` | Query bytes billed per day |

---

## Alerting on Quota Usage

Set up **Cloud Monitoring** alerts before quotas are exhausted:

```hcl
resource "google_monitoring_alert_policy" "quota_alert" {
  display_name = "CPU Quota Usage > 80%"
  combiner     = "OR"

  conditions {
    display_name = "CPU quota above 80%"
    condition_threshold {
      filter          = "metric.type=\"serviceruntime.googleapis.com/quota/rate/net_usage\" resource.type=\"consumer_quota\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}
```

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_cloud_quotas_quota_info` | Data source — read current quota and usage |
| `google_cloud_quotas_quota_preference` | Submit a quota adjustment request |
| `google_service_usage_consumer_quota_override` | Admin override for a consumer quota (legacy) |

---

## Security Guidance

- Require `roles/cloudquotas.admin` to submit quota preferences — do not grant this broadly.
- Review and approve quota increase requests through a change management process; large quota increases widen the blast radius of misconfigurations.
- Set **budget alerts** alongside quota alerts — a quota increase without a budget alert can lead to unexpected billing spikes.
- Log all quota preference changes via **Cloud Audit Logs** (`cloudquotas.googleapis.com` Admin Activity).
- Use **Org Policy** `constraints/serviceuser.services` to restrict which APIs (and their quotas) can be enabled per project.

---

## Related Docs

- [Cloud Quotas Overview](https://cloud.google.com/docs/quota)
- [Quota Preferences API](https://cloud.google.com/quotas/docs/reference/rest)
- [View and Manage Quotas](https://cloud.google.com/docs/quota/view-manage)
- [Monitoring Quota Usage](https://cloud.google.com/docs/quota/monitor-usage)
- [google_cloud_quotas_quota_preference](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_quotas_quota_preference)
- [google_service_usage_consumer_quota_override](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_usage_consumer_quota_override)
