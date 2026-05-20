# GCP Cloud Spanner Terraform Module

Reusable Terraform module for creating one or many [Cloud Spanner](https://cloud.google.com/spanner/docs) instances and one or many databases per instance.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "gcp_cloud_spanner"
├── google_spanner_instance.processing_units  (capacity_model = PROCESSING_UNITS)
├── google_spanner_instance.nodes             (capacity_model = NODES)
└── google_spanner_database.database          (one or many per instance)
```

Data flow:

```text
var.instances[] + var.project_id + var.region + var.tags
        ↓
locals: instances_map (create-filter + defaults + labels)
        instances_processing_units / instances_nodes
        databases_map (flattened key: <instance_key>--<database_key>)
        ↓
google_spanner_instance.* → google_spanner_database
        ↓
outputs: instance_ids, instance_names, database_ids, common_tags
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
| [google_spanner_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_instance) | Spanner instance using processing units or nodes |
| [google_spanner_database](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_database) | Spanner database inside an instance |

---

## Variables

### Required variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | GCP project ID where Spanner resources are created |
| `instances` | `list(object)` | One or many Spanner instance definitions |

### Optional variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Default region used when an instance does not set `region`/`config` |
| `tags` | `map(string)` | `{}` | Common governance labels merged with `managed_by` and `created_date` |

### `instances[]` fields

| Field | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable key for `for_each` |
| `name` | `string` | ✅ | — | Spanner instance name |
| `display_name` | `string` | ✅ | — | Human-readable instance name |
| `create` | `bool` | ❌ | `true` | Set `false` to skip creation |
| `region` | `string` | ❌ | `""` | Per-instance region override |
| `config` | `string` | ❌ | `""` | Explicit config (example: `regional-us-central1`) |
| `capacity_model` | `string` | ❌ | `PROCESSING_UNITS` | `PROCESSING_UNITS` or `NODES` |
| `processing_units` | `number` | ❌ | `1000` | Compute capacity for processing-unit model |
| `num_nodes` | `number` | ❌ | `1` | Node count for node model |
| `instance_edition` | `string` | ❌ | `STANDARD` | `STANDARD`, `ENTERPRISE`, `ENTERPRISE_PLUS` |
| `force_destroy` | `bool` | ❌ | `false` | Allow destroy even when databases exist |
| `labels` | `map(string)` | ❌ | `{}` | Extra labels merged with common tags |
| `autoscaling.enabled` | `bool` | ❌ | `false` | Enables Spanner autoscaling block for processing-unit model |
| `autoscaling.min_processing_units` | `number` | ❌ | `1000` | Minimum autoscaled processing units |
| `autoscaling.max_processing_units` | `number` | ❌ | `2000` | Maximum autoscaled processing units |
| `autoscaling.high_priority_cpu_utilization_percent` | `number` | ❌ | `65` | CPU target for autoscaling |
| `autoscaling.storage_utilization_percent` | `number` | ❌ | `75` | Storage utilization target for autoscaling |
| `databases` | `list(object)` | ❌ | `[]` | One or many databases per instance |

### `instances[].databases[]` fields

| Field | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable key for database map |
| `name` | `string` | ✅ | — | Spanner database name |
| `create` | `bool` | ❌ | `true` | Set `false` to skip this database |
| `database_dialect` | `string` | ❌ | `GOOGLE_STANDARD_SQL` | `GOOGLE_STANDARD_SQL` or `POSTGRESQL` |
| `ddl` | `list(string)` | ❌ | `[]` | DDL statements executed at creation time |
| `version_retention_period` | `string` | ❌ | `7d` | Time-travel retention period |
| `deletion_protection` | `bool` | ❌ | `true` | Prevent accidental DB deletion |
| `enable_drop_protection` | `bool` | ❌ | `true` | Protect against drop operations |
| `kms_key_name` | `string` | ❌ | `""` | CMEK key resource name for encryption |

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_ids` | Spanner instance IDs keyed by instance key |
| `instance_names` | Spanner instance names keyed by instance key |
| `instance_configs` | Resolved Spanner instance config keyed by instance key |
| `database_ids` | Database IDs keyed by `<instance_key>--<database_key>` |
| `database_names` | Database names keyed by `<instance_key>--<database_key>` |
| `common_tags` | Merged governance tags generated by this module |

---

## Usage

```hcl
module "gcp_cloud_spanner" {
  source = "../../modules/database/gcp_cloud_spanner"

  project_id = "my-project-id"
  region     = "us-central1"

  tags = {
    environment = "production"
    team        = "platform"
  }

  instances = [
    {
      key            = "orders-spanner"
      name           = "orders-spanner-prod"
      display_name   = "Orders Spanner Prod"
      capacity_model = "PROCESSING_UNITS"
      processing_units = 1000

      databases = [
        {
          key              = "orders-db"
          name             = "orders"
          database_dialect = "GOOGLE_STANDARD_SQL"
          ddl = [
            "CREATE TABLE orders (order_id STRING(36) NOT NULL, amount NUMERIC, created_at TIMESTAMP) PRIMARY KEY (order_id)",
          ]
        }
      ]
    }
  ]
}
```

---

## Related Docs

- [Cloud Spanner Documentation](https://cloud.google.com/spanner/docs)
- [Cloud Spanner Pricing](https://cloud.google.com/spanner/pricing)
- [Cloud Spanner Terraform Resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_instance)
- [Cloud Spanner Database Terraform Resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_database)
- [Deployment Plan → tf-plans/gcp_cloud_spanner](../../../tf-plans/gcp_cloud_spanner/README.md)
