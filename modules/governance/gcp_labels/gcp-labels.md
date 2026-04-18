# GCP Labels

[Labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels) are key-value metadata pairs attached to GCP resources for **cost attribution**, **filtering**, **automation targeting**, and **policy enforcement**. They are distinct from Tags (which gate org policies) and from network tags (which control firewall rules). Almost every GCP resource accepts labels; they are stored on the resource itself and propagated to billing exports.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Detail |
|------------|--------|
| **Scope** | Individual resource (project, VM, bucket, topic, etc.) |
| **Format** | Key: 1–63 lowercase alphanumeric chars or `-` / `_`; Value: 0–63 chars same charset |
| **Max per resource** | 64 key-value pairs |
| **Billing** | Exported to BigQuery billing dataset; filterable in Cost Table and Looker Studio |
| **Policy targeting** | Cannot gate org policies (use Tags for that) |
| **Inheritance** | Not inherited — each resource must be labelled explicitly |

---

## Core Concepts

### Label vs Tag vs Network Tag

| Feature | Labels | Resource Tags | Network Tags |
|---------|--------|---------------|-------------|
| Purpose | Cost attribution, filtering | Org policy targeting | Firewall / route targeting |
| Scope | Resource metadata | Hierarchy node binding | VM instance metadata |
| Inherited | No | Yes (from hierarchy) | No |
| Gates org policy | No | Yes | No |
| Terraform resource | `labels` argument | `google_tags_tag_binding` | `tags` argument on `google_compute_instance` |

### Recommended Label Schema

Establish a consistent schema across all resources:

| Key | Example Values | Purpose |
|-----|---------------|---------|
| `environment` | `production`, `staging`, `development` | Cost split by env |
| `team` | `platform`, `data-eng`, `security` | Team chargebacks |
| `application` | `payments-api`, `data-pipeline` | Per-app cost tracking |
| `cost-center` | `cc-1234` | Finance attribution |
| `managed-by` | `terraform`, `helm`, `manual` | Drift detection |
| `data-classification` | `public`, `internal`, `confidential` | Compliance tagging |

### Applying Labels in Terraform

Most resources accept a top-level `labels` map:

```hcl
locals {
  common_labels = {
    environment     = var.environment
    team            = var.team
    managed-by      = "terraform"
    cost-center     = var.cost_center
  }
}

resource "google_compute_instance" "web" {
  name         = "web-01"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  labels = merge(local.common_labels, {
    application = "frontend"
  })
  # ...
}

resource "google_storage_bucket" "assets" {
  name     = "my-assets-bucket"
  location = "US"

  labels = merge(local.common_labels, {
    application = "frontend"
  })
}
```

### Labelling Projects

Projects are labelled via `google_project.labels`:

```hcl
resource "google_project" "app_prod" {
  name            = "App Production"
  project_id      = "app-prod-a1b2c3"
  folder_id       = google_folder.prod.folder_id
  billing_account = var.billing_account

  labels = {
    environment = "production"
    team        = "platform"
    cost-center = "cc-1234"
  }
}
```

### Querying Labels in Billing Exports

BigQuery billing exports store labels as a `labels` ARRAY of STRUCT:

```sql
SELECT
  labels.key,
  labels.value,
  SUM(cost) AS total_cost
FROM `my-project.billing_dataset.gcp_billing_export_v1_ABCDEF_123456_GHIJKL`,
  UNNEST(labels) AS labels
WHERE
  labels.key = 'team'
  AND invoice.month = '202604'
GROUP BY 1, 2
ORDER BY total_cost DESC;
```

### Label Governance with Org Policy

Enforce required labels using a custom **Organization Policy** custom constraint (requires `constraintType: CUSTOM`):

```hcl
resource "google_org_policy_custom_constraint" "require_env_label" {
  name         = "organizations/123456789/customConstraints/custom.requireEnvLabel"
  parent       = "organizations/123456789"
  display_name = "Require environment label on Compute instances"
  description  = "All Compute instances must have an environment label"
  action_type  = "ALLOW"
  condition    = "resource.labels.environment in ['production','staging','development']"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["compute.googleapis.com/Instance"]
}

resource "google_org_policy_policy" "enforce_env_label" {
  name   = "organizations/123456789/policies/custom.requireEnvLabel"
  parent = "organizations/123456789"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
```

---

## Labels in Cost Attribution Workflow

```text
Resource created with labels
        │
        ▼
Daily billing export → BigQuery dataset
        │
        ▼
Looker Studio / Cost Table → filter/group by label key
        │
        ▼
Team / cost-center chargebacks
```

---

## Terraform Resources

| Resource | `labels` argument | Notes |
|----------|-------------------|-------|
| `google_project` | `labels` | Project-level billing attribution |
| `google_compute_instance` | `labels` | VM labels; also `metadata` for OS-level |
| `google_storage_bucket` | `labels` | Bucket labels |
| `google_bigquery_dataset` | `labels` | Dataset labels |
| `google_sql_database_instance` | `settings[].user_labels` | Nested under `settings` block |
| `google_container_cluster` | `resource_labels` | GKE cluster (uses `resource_labels` key) |
| `google_pubsub_topic` | `labels` | Topic labels |
| `google_cloudfunctions_function` | `labels` | Cloud Functions gen1 |
| `google_cloudfunctions2_function` | `labels` | Cloud Functions gen2 |

> **Note**: Some resources use `resource_labels` instead of `labels` — check the provider docs for the specific resource.

---

## Security Guidance

- Never store sensitive data (secrets, PII, tokens) in label values — labels appear in billing exports and audit logs.
- Enforce a label schema via **custom org policy constraints** to ensure consistent cost attribution from day one.
- Use `merge(local.common_labels, { ... })` in Terraform to apply a baseline set of labels everywhere and allow per-resource overrides.
- Automate label compliance checks in CI using `terraform plan` output validation or a policy-as-code tool (e.g., OPA, Checkov).
- Audit missing labels by querying the billing export for resources with no `team` or `cost-center` label.

---

## Related Docs

- [Creating and Managing Labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels)
- [Labels vs Tags](https://cloud.google.com/resource-manager/docs/tags/tags-overview#tags_versus_labels)
- [Filtering Resources by Label](https://cloud.google.com/compute/docs/labeling-resources)
- [Billing Data in BigQuery](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [Custom Org Policy Constraints](https://cloud.google.com/resource-manager/docs/organization-policy/creating-managing-custom-constraints)
