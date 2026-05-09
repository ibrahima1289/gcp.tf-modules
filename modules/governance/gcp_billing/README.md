# GCP Cloud Billing Module

Terraform module for managing [Google Cloud Billing](https://cloud.google.com/billing/docs) resources: project-to-billing-account linkage, spend budgets with multi-threshold alerting, and additive IAM bindings on the billing account.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      GCP Cloud Billing Module                           │
│                                                                         │
│  var.billing_account_id  ─────────────────────────────────────────────┐ │
│                                                                        │ │
│  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  Step 1 — google_billing_project_info (0…N)                     │  │ │
│  │  var.project_links[]                                             │  │ │
│  │  ┌──────────────────────────────────┐                           │  │ │
│  │  │ project_id → billing_account_id  │──▶ project linked ✓       │  │ │
│  │  └──────────────────────────────────┘                           │  │ │
│  └─────────────────────────────────────────────────────────────────┘  │ │
│                                                                        │ │
│  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  Step 2 — google_billing_budget (0…N)                           │  │ │
│  │  var.budgets[]                                                   │  │ │
│  │  ┌──────────────────────────────────────────────────────────┐   │  │ │
│  │  │ budget_filter                                             │   │  │ │
│  │  │  ├── projects[]      (empty = all)                       │   │  │ │
│  │  │  ├── services[]      (empty = all)                       │   │  │ │
│  │  │  ├── credit_types_treatment                              │   │  │ │
│  │  │  └── label_filters{}                                     │   │  │ │
│  │  │ amount                                                    │   │  │ │
│  │  │  ├── specified_amount (budget_amount > 0)                │   │  │ │
│  │  │  └── last_period_amount (budget_amount = 0)              │   │  │ │
│  │  │ threshold_rules[]   [50%, 90%, 100%]                     │   │  │ │
│  │  │ all_updates_rule                                          │   │  │ │
│  │  │  ├── pubsub_topic ──────────────────▶ Pub/Sub topic      │   │  │ │
│  │  │  └── monitoring_notification_channels[] ▶ Email/PagerDuty│   │  │ │
│  │  └──────────────────────────────────────────────────────────┘   │  │ │
│  └─────────────────────────────────────────────────────────────────┘  │ │
│                                                                        │ │
│  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  Step 3 — google_billing_account_iam_member (0…N)               │  │ │
│  │  var.iam_bindings[]                                              │  │ │
│  │  ┌──────────────────────────────────────────┐                   │  │ │
│  │  │ role   → member (additive binding)        │──▶ billing IAM ✓ │  │ │
│  │  └──────────────────────────────────────────┘                   │  │ │
│  └─────────────────────────────────────────────────────────────────┘  │ │
└────────────────────────────────────────────────────────────────────────┘ │
                                                                           │
                      Billing Account (XXXXXX-XXXXXX-XXXXXX) ◀────────────┘
```

---

## Resources

| Terraform Resource | Purpose |
|--------------------|---------|
| [`google_billing_project_info`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_project_info) | Link a GCP project to the billing account |
| [`google_billing_budget`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | Spend budget with multi-threshold alerts, Pub/Sub, and email notification |
| [`google_billing_account_iam_member`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_account_iam) | Additive IAM binding on the billing account |

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |

### Required IAM to run this module

| Permission | Why |
|-----------|-----|
| `roles/billing.user` | Create and manage budgets |
| `roles/billing.admin` | Manage IAM bindings on the billing account |
| `roles/resourcemanager.projectBillingManager` | Link projects to a billing account |

---

## Usage

### Single budget with Pub/Sub notification

```hcl
module "billing" {
  source = "../../modules/governance/gcp_billing"

  billing_account_id = "ABCDEF-123456-GHIJKL"
  project_id         = "my-project-123"

  tags = {
    owner = "finops-team"
    env   = "production"
  }

  budgets = [
    {
      key           = "monthly-all"
      display_name  = "Monthly — All Projects"
      budget_amount = 5000
      threshold_percents = [50, 80, 90, 100]
      pubsub_topic  = "projects/my-project-123/topics/billing-alerts"
    }
  ]
}
```

### Multiple budgets with project and service filters

```hcl
module "billing" {
  source = "../../modules/governance/gcp_billing"

  billing_account_id = "ABCDEF-123456-GHIJKL"
  project_id         = "my-project-123"

  project_links = [
    { project_id = "app-prod-456" },
    { project_id = "data-prod-789" }
  ]

  budgets = [
    {
      key           = "app-prod"
      display_name  = "App Prod — Compute + GKE"
      budget_amount = 3000
      projects      = ["app-prod-456"]
      services      = ["6F81-5844-456A", "95FF-2EF5-5EA1"]  # Compute Engine, GKE
      threshold_percents = [75, 90, 100]
      spend_basis   = "FORECASTED_SPEND"
    },
    {
      key           = "data-prod"
      display_name  = "Data Prod — BigQuery"
      budget_amount = 0   # 0 = use last period spend as budget
      projects      = ["data-prod-789"]
    }
  ]

  iam_bindings = [
    {
      role   = "roles/billing.viewer"
      member = "group:finops@example.com"
    }
  ]
}
```

---

## Variables

### Root

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `billing_account_id` | `string` | ✅ | — | Billing account ID in format `XXXXXX-XXXXXX-XXXXXX`. |
| `project_id` | `string` | ✅ | — | GCP project ID for provider context. |
| `region` | `string` | | `"us-central1"` | Default GCP region. |
| `tags` | `map(string)` | | `{}` | Extra labels merged into `common_labels` output. |
| `project_links` | `list(object)` | | `[]` | Projects to link to the billing account — see table below. |
| `budgets` | `list(object)` | | `[]` | Billing budgets — see table below. |
| `iam_bindings` | `list(object)` | | `[]` | Additive IAM bindings on the billing account — see table below. |

### `project_links[]` object

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID to link to the billing account. |
| `create` | `bool` | | `true` | Set `false` to skip without removing from config. |

### `budgets[]` object

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Unique Terraform state key. |
| `display_name` | `string` | ✅ | — | Human-readable budget name in the Cloud Console. |
| `create` | `bool` | | `true` | Set `false` to skip without removing from config. |
| `budget_amount` | `number` | | `0` | Spend threshold in `currency_code`. `0` = use last period spend. |
| `currency_code` | `string` | | `"USD"` | ISO 4217 currency code. |
| `projects` | `list(string)` | | `[]` | Project IDs to scope the budget (empty = all projects). |
| `services` | `list(string)` | | `[]` | GCP service IDs to filter (empty = all services). |
| `credit_types_treatment` | `string` | | `"INCLUDE_ALL_CREDITS"` | `INCLUDE_ALL_CREDITS`, `EXCLUDE_ALL_CREDITS`, or `INCLUDE_SPECIFIED_CREDITS`. |
| `label_filters` | `map(string)` | | `{}` | Single resource label key→value filter (one pair supported by the API). |
| `threshold_percents` | `list(number)` | | `[50, 90, 100]` | Alert thresholds as integer percentages of `budget_amount`. |
| `spend_basis` | `string` | | `"CURRENT_SPEND"` | `CURRENT_SPEND` (actual) or `FORECASTED_SPEND` (projected). |
| `pubsub_topic` | `string` | | `""` | Full Pub/Sub topic path for programmatic responses. |
| `notification_channels` | `list(string)` | | `[]` | Cloud Monitoring notification channel resource names. |
| `disable_default_iam_recipients` | `bool` | | `false` | Suppress default email to billing admins/users. |

### `iam_bindings[]` object

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `role` | `string` | ✅ | IAM role (e.g. `roles/billing.viewer`). |
| `member` | `string` | ✅ | IAM principal (e.g. `user:admin@example.com`, `group:finops@example.com`). |

---

## Outputs

| Name | Description |
|------|-------------|
| `project_billing_links` | `map(string)` — project_id → billing account ID for active links. |
| `budget_ids` | `map(string)` — budget key → resource name for active budgets. |
| `budget_names` | `map(string)` — budget key → display name for active budgets. |
| `iam_binding_ids` | `map(string)` — role/member → binding ID for all IAM bindings. |
| `common_labels` | `map(string)` — base labels: `managed-by`, `created-date`, and `var.tags`. |

---

## Notes

- **Budget thresholds are advisory**: exceeding a budget threshold does not stop or disable services.
- **last_period_amount**: Set `budget_amount = 0` to automatically track the previous calendar period's actual spend — useful for anomaly detection without a fixed threshold.
- **Pub/Sub integration**: Connect the `pubsub_topic` output to a Cloud Function or Workflows instance to programmatically disable billing when a threshold is breached. See [Cloud Billing budget notifications](https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications).
- **Additive IAM**: The module uses `google_billing_account_iam_member` (additive), not `_binding` (authoritative), so it will not overwrite bindings managed outside Terraform.
- **Billing export**: BigQuery export is configured at the billing account level in the console; there is no `google_billing_*` Terraform resource for export setup. Use a Terraform `null_resource` or manual step.
