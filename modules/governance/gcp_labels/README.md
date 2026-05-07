# GCP Labels Module

Terraform module for managing a **standardised label schema** across GCP resources. Because labels are metadata arguments (not standalone GCP resources), the module uses `terraform_data` sentinels to track each label profile in state — surfacing label drift in `terraform plan` before any resource is re-applied.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                      GCP Labels Module                             │
│                                                                    │
│  Inputs                     Computed                  Outputs      │
│  ─────────────────────────  ─────────────────────────────────────  │
│  var.label_sets[]           locals.computed_labels[]               │
│  ┌────────────────────┐    ┌──────────────────────────┐            │
│  │ key                │    │ managed-by  = terraform  │            │
│  │ environment        │───▶│ created-date = YYYY-MM-DD│──▶ label_sets["key"]
│  │ team               │    │ environment  = ...       │            │
│  │ application        │    │ team         = ...       │            │
│  │ cost_center        │    │ application  = ...       │            │
│  │ data_classification│    │ cost-center  = ...       │            │
│  │ extra_labels{}     │    │ data-class.  = ...       │            │
│  └────────────────────┘    │ <extra_labels>           │──▶ common_labels
│                             └──────────────────────────┘            │
│  var.tags{}                          ▲                              │
│  (owner, project, …) ───────────────┘                              │
│                                                                    │
│  terraform_data.label_sets[key]   ← state sentinel per profile     │
│  triggers_replace = jsonencode(computed_labels[key])               │
│  → plan shows diff on any label change                             │
└────────────────────────────────────────────────────────────────────┘

     Labels consumed by other modules / resources:

     google_compute_instance.web { labels = module.labels.label_sets["platform"] }
     google_storage_bucket.data  { labels = module.labels.label_sets["data-eng"] }
     google_sql_database_instance{ labels = module.labels.label_sets["security"] }
```

---

## Resources

| Terraform Resource | Purpose |
|--------------------|---------|
| [`terraform_data`](https://developer.hashicorp.com/terraform/language/resources/terraform-data) | State sentinel — one per active label_set; replaces on any label value change |

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.5` |

No GCP provider block is needed — this module creates no GCP API resources.

---

## Usage

### Basic — single label profile

```hcl
module "labels" {
  source = "../../modules/governance/gcp_labels"

  project_id = "my-project-123"
  region     = "us-central1"

  tags = {
    owner   = "infra-team"
    project = "my-project-123"
  }

  label_sets = [
    {
      key         = "platform"
      environment = "production"
      team        = "platform"
      application = "shared-infra"
      cost_center = "cc-1001"
    }
  ]
}

# Apply labels to a resource
resource "google_storage_bucket" "assets" {
  name     = "my-assets-bucket"
  location = "US"
  labels   = module.labels.label_sets["platform"]
}
```

### Multiple profiles with data classification

```hcl
module "labels" {
  source = "../../modules/governance/gcp_labels"

  project_id = "my-project-123"
  region     = "us-central1"

  tags = { owner = "platform-team" }

  label_sets = [
    {
      key                 = "payments"
      environment         = "production"
      team                = "payments"
      application         = "payments-api"
      cost_center         = "cc-2001"
      data_classification = "confidential"
    },
    {
      key         = "analytics"
      environment = "production"
      team        = "data-eng"
      application = "analytics-pipeline"
      cost_center = "cc-3001"
      extra_labels = {
        pipeline-version = "v3"
        data-source      = "clickstream"
      }
    }
  ]
}
```

### Consuming labels in another module

```hcl
module "gke" {
  source = "../../modules/compute/gcp_gke"

  # ...
  tags = module.labels.label_sets["platform"]
}
```

---

## Variables

### Root

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID. |
| `region` | `string` | | `"us-central1"` | Default GCP region. |
| `tags` | `map(string)` | | `{}` | Extra key-value pairs merged into every label map (e.g. `owner`, `project`). |
| `label_sets` | `list(object)` | | `[]` | List of label profiles — see table below. |

### `label_sets[]` object

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Unique profile identifier used as the Terraform state key. |
| `create` | `bool` | | `true` | Set `false` to compute labels without creating a state sentinel. |
| `environment` | `string` | ✅ | — | Deployment environment: `production`, `staging`, `development`. |
| `team` | `string` | ✅ | — | Owning team slug, e.g. `platform`, `data-eng`, `security`. |
| `application` | `string` | ✅ | — | Application or workload name, e.g. `payments-api`. |
| `cost_center` | `string` | ✅ | — | Finance cost-center code, e.g. `cc-1234`. |
| `data_classification` | `string` | | `""` | Data sensitivity: `public`, `internal`, `confidential`, `restricted`. Omit to exclude the label. |
| `extra_labels` | `map(string)` | | `{}` | Arbitrary additional labels merged last (highest precedence). Keys must follow GCP label naming rules. |

### Computed label keys (in output maps)

| Label Key | Source | Example Value |
|-----------|--------|--------------|
| `managed-by` | hardcoded | `terraform` |
| `created-date` | `formatdate(timestamp())` | `2026-05-06` |
| `environment` | `ls.environment` | `production` |
| `team` | `ls.team` | `platform` |
| `application` | `ls.application` | `payments-api` |
| `cost-center` | `ls.cost_center` | `cc-1234` |
| `data-classification` | `ls.data_classification` | `confidential` |
| *(extra keys)* | `ls.extra_labels` | `pipeline-version = v3` |

---

## Outputs

| Name | Description |
|------|-------------|
| `label_sets` | `map(map(string))` — computed label map for each **active** (`create=true`) label_set key. |
| `all_label_sets` | `map(map(string))` — computed label map for **all** entries including `create=false`. |
| `common_labels` | `map(string)` — base labels shared across all resources: `managed-by`, `created-date`, and `var.tags`. |

---

## Notes

- **GCP label key rules**: lowercase letters, digits, hyphens, underscores; 1–63 chars. Values: 0–63 chars same charset. Max 64 labels per resource.
- **Labels ≠ Tags**: Use [Resource Tags](https://cloud.google.com/resource-manager/docs/tags/tags-overview) (`google_tags_tag_binding`) to gate Organisation Policies. Labels cannot enforce policies.
- **Drift detection**: The `triggers_replace` value on `terraform_data` is the JSON-encoded label map. Any label change will show as a resource replacement in `plan` — no force-apply required.
- **Inheritance**: GCP does not inherit labels down the resource hierarchy. Each resource must have labels applied explicitly.
- **Billing export**: Labels appear in the BigQuery billing export. Use a consistent schema across all resources for accurate cost allocation.
