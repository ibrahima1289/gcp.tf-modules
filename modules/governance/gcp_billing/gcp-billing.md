# GCP Billing

[Cloud Billing](https://cloud.google.com/billing/docs) links GCP projects to a payment method and controls how costs are tracked, attributed, and reported. A **Billing Account** is the financial container — it accrues charges from all linked projects, applies committed use discounts and sustained use discounts, and issues invoices. Terraform manages billing accounts, budget alerts, and project-to-billing-account linkage via the `google_billing_*` and `google_cloud_billing_*` resource families.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Concept | Description |
|---------|-------------|
| **Billing Account** | Payment container; linked to one or more projects |
| **Self-serve account** | Paid by credit card; managed in Cloud Console |
| **Invoiced account** | Paid via invoice (NET30/NET60); requires Google Sales |
| **Sub-account** | Child billing account under a reseller master account |
| **Budget** | Spend threshold with alert notifications |
| **Billing Export** | Streaming cost data to BigQuery for analysis |
| **Committed Use Discounts (CUD)** | 1- or 3-year resource commitments for discounted pricing |
| **Savings Plans** | Flexible spend commitment for Compute |

---

## Core Concepts

### Billing Account ↔ Project Relationship

```text
Billing Account (ABCDEF-123456-GHIJKL)
├── Project: app-prod         → accrues Compute, GKE, Cloud SQL costs
├── Project: logging-prod     → accrues Cloud Logging, GCS costs
└── Project: networking-hub   → accrues Interconnect, VPN costs
```

A project can be linked to only **one** billing account at a time, but a billing account can have unlimited linked projects.

### Linking a Project to a Billing Account

```hcl
resource "google_billing_project_info" "link" {
  project         = google_project.app_prod.project_id
  billing_account = var.billing_account_id   # format: "ABCDEF-123456-GHIJKL"
}
```

> Requires `roles/billing.user` on the billing account and `roles/resourcemanager.projectBillingManager` on the project.

### Budgets and Alerts

Budgets monitor cumulative spend against a configurable threshold and fire Pub/Sub notifications or email alerts when thresholds are crossed. Budget alert thresholds are **advisory only** — they do not stop resource usage.

```hcl
resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account_id
  display_name    = "Monthly Budget — App Prod"

  budget_filter {
    projects = ["projects/${google_project.app_prod.number}"]
    services = []   # empty = all services
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "5000"   # $5,000 / month
    }
  }

  threshold_rules {
    threshold_percent = 0.5   # alert at 50%
  }
  threshold_rules {
    threshold_percent = 0.9   # alert at 90%
  }
  threshold_rules {
    threshold_percent = 1.0   # alert at 100%
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    pubsub_topic                     = google_pubsub_topic.billing_alerts.id
    schema_version                   = "1.0"
    monitoring_notification_channels = [google_monitoring_notification_channel.email.name]
    disable_default_iam_alerts       = false
  }
}
```

### Billing Export to BigQuery

Enable billing export once per billing account; all projects linked to that account stream cost data to the dataset:

```hcl
resource "google_billing_account_iam_member" "bq_export" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.viewer"
  member             = "serviceAccount:${google_service_account.billing_export.email}"
}
```

> BigQuery billing export is configured in the **Cloud Console** under Billing → Billing Export (Terraform cannot currently create the export config). Manage the dataset and table permissions via Terraform.

```sql
-- Total cost by project and service for current month
SELECT
  project.name        AS project,
  service.description AS service,
  SUM(cost)           AS total_cost,
  currency
FROM `my-org.billing_dataset.gcp_billing_export_v1_ABCDEF_123456_GHIJKL`
WHERE DATE(usage_start_time) >= DATE_TRUNC(CURRENT_DATE(), MONTH)
GROUP BY 1, 2, 4
ORDER BY total_cost DESC
LIMIT 20;
```

### IAM Roles on Billing Accounts

| Role | Capability |
|------|-----------|
| `roles/billing.admin` | Full control — link/unlink projects, manage billing account |
| `roles/billing.user` | Link projects to the billing account |
| `roles/billing.viewer` | View cost and usage data |
| `roles/billing.projectManager` | Manage project linkage without billing account access |
| `roles/budgets.editor` | Create and modify budgets |
| `roles/budgets.viewer` | View budgets |

```hcl
resource "google_billing_account_iam_member" "billing_viewer" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.viewer"
  member             = "group:finance-team@example.com"
}
```

### Cost Attribution with Labels

Labels on resources are exported to the billing dataset and enable fine-grained cost breakdowns:

| Label Key | Billing Query Use |
|-----------|------------------|
| `environment` | Compare prod vs non-prod spend |
| `team` | Chargeback per team |
| `cost-center` | Finance department attribution |
| `application` | Per-application cost tracking |

See [GCP Labels](../gcp_labels/gcp-labels.md) for the full label governance guide.

---

## Budget Automation — Stop Billing on Threshold

Budgets can trigger a Cloud Function via Pub/Sub to **disable billing** on a project automatically (useful for sandbox accounts):

```text
Budget threshold exceeded
        │
        ▼
Pub/Sub topic
        │
        ▼
Cloud Function
        │
        ▼
google_billing_project_info: billing_account = ""  (unlinks billing)
```

> Use with caution — unlinking billing disables all paid APIs and stops running resources in the project.

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_billing_project_info` | Link a project to a billing account |
| `google_billing_budget` | Create spend budgets with alert thresholds |
| `google_billing_account_iam_member` | Grant IAM roles on a billing account |
| `google_billing_account_iam_binding` | Authoritative IAM binding on a billing account |
| `data.google_billing_account` | Look up a billing account by display name or ID |

---

## Security Guidance

- Grant `roles/billing.admin` only to a small group of finance/infra leads — it allows project relinking which can hide costs.
- Use `roles/billing.viewer` for engineering teams who need cost visibility without management rights.
- Set budgets on **every project** with alerts at 50%, 90%, and 100% forecast; route alerts to both Pub/Sub and an email channel.
- Enable **Billing Export to BigQuery** from day one — retroactive export is not available.
- Audit billing IAM changes via **Cloud Audit Logs** (`cloudbilling.googleapis.com` Admin Activity).
- Consider **sub-accounts** for multi-tenant or reseller setups to isolate billing between customers.
- Apply `roles/billing.projectManager` to project automation service accounts rather than `roles/billing.admin`.

---

## Related Docs

- [Cloud Billing Overview](https://cloud.google.com/billing/docs/overview)
- [Billing Budgets](https://cloud.google.com/billing/docs/how-to/budgets)
- [Export Billing Data to BigQuery](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [Billing IAM Roles](https://cloud.google.com/billing/docs/how-to/billing-access)
- [google_billing_budget](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget)
- [google_billing_project_info](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_project_info)
