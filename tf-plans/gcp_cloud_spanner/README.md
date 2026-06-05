# GCP Cloud Spanner Deployment Plan

Wrapper configuration for the [GCP Cloud Spanner module](../../modules/database/gcp_cloud_spanner/README.md).

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_cloud_spanner/
├── providers.tf     → Terraform and Google provider requirements
├── variables.tf     → project_id, region, tags, instances[]
├── locals.tf        → generated created_date value
├── main.tf          → module "gcp_cloud_spanner" wrapper call
├── outputs.tf       → pass-through outputs from module
├── terraform.tfvars → example multi-instance input
└── README.md        → usage and variable reference
        ↓
modules/database/gcp_cloud_spanner/
├── google_spanner_instance.processing_units
├── google_spanner_instance.nodes
└── google_spanner_database.database
```

---

## Prerequisites

- GCP project with [Cloud Spanner API](https://console.cloud.google.com/apis/library/spanner.googleapis.com) enabled
- Terraform `>= 1.5`
- Google provider `>= 6.0`
- IAM role `roles/spanner.admin` on target project

---

## Apply Workflow

1. Authenticate with `gcloud auth application-default login --no-launch-browser`.
2. Set the project with `gcloud config set project <project-id>`.
3. Enable API with `gcloud services enable spanner.googleapis.com --project=<project-id>`.
4. Update `terraform.tfvars` for your environment.
5. Run `terraform init`, `terraform plan -out=tfplan`, and `terraform apply tfplan`.

---

## Variables

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Target GCP project ID |
| `instances` | `list(object)` | One or many Spanner instance definitions |

### Optional

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Default region fallback |
| `tags` | `map(string)` | `{}` | Common governance tags |

For full nested schema, see [module variable reference](../../modules/database/gcp_cloud_spanner/README.md#variables).

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_ids` | Spanner instance IDs keyed by instance key |
| `instance_names` | Spanner instance names keyed by instance key |
| `instance_configs` | Spanner configs keyed by instance key |
| `database_ids` | Database IDs keyed by `<instance_key>--<database_key>` |
| `database_names` | Database names keyed by `<instance_key>--<database_key>` |
| `common_tags` | Merged governance tags used in this plan |

---

## Related Docs

- [GCP Cloud Spanner Module](../../modules/database/gcp_cloud_spanner/README.md)
- [Cloud Spanner Documentation](https://cloud.google.com/spanner/docs)
- [Cloud Spanner Instance Terraform Resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_instance)
- [Cloud Spanner Database Terraform Resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_database)
