# GCP Cloud SQL Terraform Module

Reusable Terraform module for creating one or many [Google Cloud SQL](https://cloud.google.com/sql/docs) instances (MySQL, PostgreSQL, SQL Server) with databases, users, backups, VPC private IP, Query Insights, and maintenance window controls.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "gcp_cloud_sql"
├── google_sql_database_instance.instance    (one per instances[] entry)
│   ├── settings.backup_configuration {}
│   ├── settings.ip_configuration {}
│   │   └── dynamic authorized_networks {}  (one per authorized_networks[])
│   ├── settings.maintenance_window {}
│   ├── dynamic insights_config {}           (when insights_config_enabled = true)
│   └── dynamic database_flags {}           (one per database_flags[])
├── google_sql_database.database             (one per instances[].databases[] entry)
└── google_sql_user.user                     (one per instances[].users[] entry)
```

Data flow:

```text
var.instances[] + var.project_id + var.region + var.tags
        ↓
locals: instances_map (create filter + region + label merge)
        databases_map (flattened, keyed "<instance_key>--<db_name>")
        users_map     (flattened, keyed "<instance_key>--<user_name>")
        ↓
google_sql_database_instance  →  google_sql_database
                              →  google_sql_user
        ↓
outputs: connection_name, public_ip, private_ip, db_ids, user_ids
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
| [`google_sql_database_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | Cloud SQL instance (MySQL, PostgreSQL, or SQL Server) |
| [`google_sql_database`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | Logical database inside an instance |
| [`google_sql_user`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | Database user (built-in or Cloud IAM) |

---

## Variables

### Top-level (required)

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | GCP project ID for all instances |
| `instances` | `list(object)` | One or many Cloud SQL instance configurations |

### Top-level (optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Default region when instance does not override |
| `tags` | `map(string)` | `{}` | Governance tags merged into every instance's user_labels |

### `instances[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable key for `for_each` |
| `name` | `string` | required | Globally unique Cloud SQL instance name |
| `database_version` | `string` | required | Engine version: `MYSQL_8_0`, `POSTGRES_15`, `SQLSERVER_2022_STANDARD`, etc. |
| `region` | `string` | `""` | Per-instance region override; falls back to `var.region` |
| `deletion_protection` | `bool` | `true` | Prevents accidental deletion via Terraform |
| `create` | `bool` | `true` | Set `false` to skip this instance without removing it from config |
| `tier` | `string` | `db-n1-standard-2` | Machine type (e.g. `db-f1-micro`, `db-n1-standard-4`) |
| `edition` | `string` | `ENTERPRISE` | `ENTERPRISE` or `ENTERPRISE_PLUS` |
| `availability_type` | `string` | `ZONAL` | `ZONAL` (single-zone) or `REGIONAL` (HA with automatic failover) |
| `disk_size` | `number` | `10` | Disk size in GB (minimum 10) |
| `disk_type` | `string` | `PD_SSD` | `PD_SSD` or `PD_HDD` |
| `disk_autoresize` | `bool` | `true` | Automatically increase disk when nearing capacity |
| `disk_autoresize_limit` | `number` | `0` | Max autoresize GB (`0` = unlimited) |
| `backup_enabled` | `bool` | `true` | Enable automated backups |
| `binary_log_enabled` | `bool` | `false` | Enable binary logging (MySQL only; required for PITR on MySQL) |
| `point_in_time_recovery_enabled` | `bool` | `false` | Enable PITR (PostgreSQL / SQL Server) |
| `backup_start_time` | `string` | `02:00` | UTC time window for backup (HH:MM) |
| `transaction_log_retention_days` | `number` | `7` | Days to retain transaction logs |
| `retained_backups` | `number` | `7` | Number of automated backups to retain |
| `backup_location` | `string` | `""` | Backup region; empty = same region as instance |
| `ipv4_enabled` | `bool` | `true` | Enable public IPv4 address |
| `require_ssl` | `bool` | `true` | (deprecated; use `ssl_mode`) |
| `ssl_mode` | `string` | `ENCRYPTED_ONLY` | `ALLOW_UNENCRYPTED_AND_ENCRYPTED`, `ENCRYPTED_ONLY`, or `TRUSTED_CLIENT_CERTIFICATE_REQUIRED` |
| `private_network` | `string` | `""` | VPC network self-link for private IP; empty = no private IP |
| `authorized_networks` | `list(object)` | `[]` | CIDR allowlist entries for public IP access |
| `maintenance_window_day` | `number` | `7` | Day of week for maintenance (1=Mon … 7=Sun) |
| `maintenance_window_hour` | `number` | `2` | UTC hour for maintenance window |
| `maintenance_window_update_track` | `string` | `stable` | `canary` or `stable` |
| `insights_config_enabled` | `bool` | `false` | Enable Query Insights |
| `query_string_length` | `number` | `1024` | Max query string length captured by Insights |
| `record_application_tags` | `bool` | `false` | Record application tags in Insights |
| `record_client_address` | `bool` | `false` | Record client IP in Insights |
| `query_plans_per_minute` | `number` | `5` | Query plan samples per minute |
| `database_flags` | `list(object)` | `[]` | Engine flags: `[{ name, value }]` |
| `databases` | `list(object)` | `[]` | Databases: `[{ name, charset?, collation? }]` |
| `users` | `list(object)` | `[]` | Users: `[{ name, password?, host?, type? }]` |
| `labels` | `map(string)` | `{}` | Additional labels merged with common tags |

### `authorized_networks[]` fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | required | Display name for the network entry |
| `value` | `string` | required | CIDR range (e.g. `10.0.0.0/8`) |
| `expiration_time` | `string` | `""` | RFC 3339 expiry; empty = no expiry |

### `users[]` type values

| `type` | Description |
|--------|-------------|
| `BUILT_IN` | Standard database user with password |
| `CLOUD_IAM_USER` | Google account IAM user (no password) |
| `CLOUD_IAM_SERVICE_ACCOUNT` | Service account IAM user (no password) |
| `CLOUD_IAM_GROUP` | Cloud Identity group IAM user (no password) |

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_ids` | Resource IDs keyed by instance key |
| `instance_names` | Instance names keyed by instance key |
| `instance_connection_names` | `project:region:instance` strings for Cloud SQL Auth Proxy |
| `instance_self_links` | REST API self-links keyed by instance key |
| `public_ip_addresses` | Public IPs (when `ipv4_enabled = true`) keyed by instance key |
| `private_ip_addresses` | Private IPs (when `private_network` is set) keyed by instance key |
| `database_ids` | DB resource IDs keyed by `<instance_key>--<db_name>` |
| `user_ids` | User resource IDs keyed by `<instance_key>--<user_name>` |
| `instance_regions` | Resolved region for each instance |
| `common_tags` | Merged governance tags applied by this module |

---

## Usage

```hcl
module "gcp_cloud_sql" {
  source = "../../modules/database/gcp_cloud_sql"

  project_id = "my-project-id"
  region     = "us-central1"

  tags = {
    environment = "production"
    team        = "platform"
  }

  instances = [
    {
      key              = "app-db"
      name             = "my-app-postgres-prod"
      database_version = "POSTGRES_15"
      availability_type = "REGIONAL"
      tier             = "db-n1-standard-4"
      disk_size        = 50

      point_in_time_recovery_enabled = true
      backup_enabled                 = true

      ipv4_enabled    = false
      private_network = "projects/my-project-id/global/networks/my-vpc"

      databases = [
        { name = "appdb" }
      ]

      users = [
        { name = "appuser", password = "changeme", type = "BUILT_IN" }
      ]
    }
  ]
}
```

### Cloud SQL Auth Proxy connection

Use the `instance_connection_names` output with the [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy):

```bash
cloud-sql-proxy \
  --port 5432 \
  $(terraform output -raw instance_connection_names["app-db"])
```

### IAM database authentication (PostgreSQL)

```hcl
users = [
  {
    name = "iam-sa@my-project-id.iam"
    type = "CLOUD_IAM_SERVICE_ACCOUNT"
  }
]
```

---

## Validation Behaviour

| Rule | Error |
|------|-------|
| Duplicate `key` values | `instances[*].key values must be unique` |
| Duplicate `name` values | `instances[*].name values must be unique` |
| Invalid `availability_type` | Must be `ZONAL` or `REGIONAL` |
| Invalid `disk_type` | Must be `PD_SSD` or `PD_HDD` |
| Invalid `edition` | Must be `ENTERPRISE` or `ENTERPRISE_PLUS` |
| Invalid `ssl_mode` | Must be one of three allowed values |

---

## Related Docs

- [Cloud SQL Overview](https://cloud.google.com/sql/docs)
- [Cloud SQL Pricing](https://cloud.google.com/sql/pricing)
- [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy)
- [Cloud SQL IAM Database Authentication](https://cloud.google.com/sql/docs/postgres/iam-authentication)
- [google_sql_database_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance)
- [Deployment Plan → tf-plans/gcp_cloud_sql](../../../tf-plans/gcp_cloud_sql/README.md)
