# GCP AlloyDB Terraform Module

Reusable Terraform module for creating one or many [AlloyDB for PostgreSQL](https://cloud.google.com/alloydb/docs) clusters with primary instances, horizontally scalable read pool instances, automated and continuous backups, CMEK encryption, and maintenance window controls.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "gcp_alloydb"
├── google_alloydb_cluster.cluster              (one per clusters[] entry)
│   ├── network_config {}                       — PSA VPC peering
│   ├── automated_backup_policy {}
│   │   ├── weekly_schedule {}
│   │   ├── dynamic quantity_based_retention {} (when retention_days = 0)
│   │   └── dynamic time_based_retention {}     (when retention_days > 0)
│   ├── continuous_backup_config {}             — PITR window (1–35 days)
│   ├── dynamic encryption_config {}            (when kms_key_name is set)
│   ├── initial_user {}
│   └── maintenance_update_policy {}
├── google_alloydb_instance.primary             (one per active cluster)
│   ├── machine_config {}
│   ├── ssl_config {}
│   └── query_insights_config {}
└── google_alloydb_instance.read_pool           (one per read_pools[] entry)
    ├── machine_config {}
    ├── read_pool_config {}                     — node_count controls horizontal scale
    └── ssl_config {}
```

Data flow:

```text
var.clusters[] + var.project_id + var.region + var.tags
        ↓
locals: clusters_map  (create filter + region + label merge)
        read_pools_map (flattened, keyed "<cluster_key>--<instance_id>")
        ↓
google_alloydb_cluster  →  google_alloydb_instance.primary
                        →  google_alloydb_instance.read_pool[]
        ↓
outputs: cluster_ids, primary_ip_addresses, read_pool_ip_addresses
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
| [`google_alloydb_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_cluster) | AlloyDB cluster — top-level container with backup, PITR, CMEK, and maintenance settings |
| [`google_alloydb_instance` (PRIMARY)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_instance) | Single read/write primary instance with configurable vCPU, HA, and SSL |
| [`google_alloydb_instance` (READ_POOL)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_instance) | Horizontally scalable read pool for read-heavy workloads |

---

## Variables

### Top-level (required)

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | GCP project ID for all clusters |
| `clusters` | `list(object)` | One or many AlloyDB cluster configurations |

### Top-level (optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `us-central1` | Default region when cluster does not override |
| `tags` | `map(string)` | `{}` | Governance labels merged into every cluster's labels map |

### `clusters[]` fields

#### Core

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable key for `for_each` |
| `name` | `string` | required | AlloyDB cluster ID (unique within project + region) |
| `network` | `string` | required | VPC self-link or ID; PSA must be pre-configured |
| `region` | `string` | `""` | Per-cluster region; falls back to `var.region` |
| `create` | `bool` | `true` | Set `false` to skip cluster without removing from config |
| `cluster_type` | `string` | `PRIMARY` | `PRIMARY` or `SECONDARY` (cross-region replica) |
| `deletion_protection` | `bool` | `true` | Prevent accidental Terraform-driven deletion |
| `labels` | `map(string)` | `{}` | Additional labels merged with common tags |

#### Backup and PITR

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `automated_backup_enabled` | `bool` | `true` | Enable automated scheduled backups |
| `automated_backup_start_time` | `string` | `02:00` | UTC start time `HH:MM` for backup window |
| `automated_backup_days_of_week` | `list(string)` | `["MONDAY"]` | Days to run backups: `MONDAY`…`SUNDAY` |
| `automated_backup_retention_count` | `number` | `7` | Number of backups to retain (count-based) |
| `automated_backup_retention_days` | `number` | `0` | Days of backup retention (`0` = use count-based) |
| `automated_backup_location` | `string` | `""` | Backup region; empty = same as cluster region |
| `point_in_time_recovery_enabled` | `bool` | `true` | Enable PITR (requires continuous backup) |
| `continuous_backup_enabled` | `bool` | `true` | Enable continuous backup for PITR |
| `continuous_backup_recovery_window` | `number` | `14` | PITR recovery window in days (1–35) |

#### Security

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `initial_user` | `string` | `alloydbadmin` | Initial PostgreSQL admin user |
| `initial_password` | `string` | `""` | Password for initial user; set via tfvars or Secret Manager reference |
| `kms_key_name` | `string` | `""` | KMS key resource name for CMEK; empty = Google-managed key |

#### Maintenance

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `maintenance_window_day` | `string` | `SUNDAY` | Day for maintenance (`MONDAY`…`SUNDAY`) |
| `maintenance_window_hour` | `number` | `2` | UTC hour for maintenance window (0–23) |

### `clusters[].primary` fields (optional object)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `instance_id` | `string` | `primary` | Instance ID suffix appended to cluster name |
| `cpu_count` | `number` | `2` | vCPUs: `2`, `4`, `8`, `16`, or `64` |
| `availability_type` | `string` | `REGIONAL` | `REGIONAL` (auto HA failover) or `ZONAL` (single-zone) |
| `database_flags` | `map(string)` | `{}` | Engine-level flags, e.g. `{ "max_connections" = "500" }` |
| `require_connectors` | `bool` | `false` | Require [AlloyDB Auth Proxy](https://cloud.google.com/alloydb/docs/auth-proxy/overview) for all connections |
| `ssl_mode` | `string` | `ENCRYPTED_ONLY` | `ENCRYPTED_ONLY` or `ALLOW_UNENCRYPTED_AND_ENCRYPTED` |
| `enable_public_ip` | `bool` | `false` | Enable public IP (preview feature) |
| `columnar_engine_enabled` | `bool` | `true` | Enable in-memory columnar cache for analytics |
| `columnar_engine_memory_size_gb` | `number` | `0` | Columnar cache size GB; `0` = auto |

### `clusters[].read_pools[]` fields (optional list)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `instance_id` | `string` | required | Unique ID within the cluster for this read pool |
| `cpu_count` | `number` | `2` | vCPUs per read-pool node |
| `node_count` | `number` | `1` | Number of nodes in the pool (horizontal scaling) |
| `database_flags` | `map(string)` | `{}` | Engine-level flags for read pool nodes |
| `require_connectors` | `bool` | `false` | Require AlloyDB Auth Proxy |
| `ssl_mode` | `string` | `ENCRYPTED_ONLY` | SSL enforcement mode |
| `enable_public_ip` | `bool` | `false` | Enable public IP |
| `create` | `bool` | `true` | Set `false` to skip this pool without removing from config |

---

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_ids` | Cluster resource IDs keyed by cluster key |
| `cluster_names` | Cluster IDs (name) keyed by cluster key |
| `cluster_uids` | System-assigned UIDs keyed by cluster key |
| `primary_instance_ids` | Primary instance resource IDs keyed by cluster key |
| `primary_instance_names` | Primary instance names keyed by cluster key |
| `primary_ip_addresses` | Private IPs of primary instances keyed by cluster key |
| `read_pool_ids` | Read pool resource IDs keyed by `<cluster_key>--<instance_id>` |
| `read_pool_instance_names` | Read pool instance names keyed by composite key |
| `read_pool_ip_addresses` | Private IPs of read pool instances keyed by composite key |
| `cluster_regions` | Resolved regions keyed by cluster key |
| `common_tags` | Governance labels generated by this module call |

---

## Prerequisites

- GCP project with [AlloyDB API enabled](https://cloud.google.com/alloydb/docs/project-enable-access) (`alloydb.googleapis.com`)
- VPC network with [Private Service Access](https://cloud.google.com/alloydb/docs/configure-connectivity) configured
- IAM role: [`roles/alloydb.admin`](https://cloud.google.com/alloydb/docs/auth-and-access/overview) on the project
- For CMEK: KMS key with `roles/cloudkms.cryptoKeyEncrypterDecrypter` granted to the AlloyDB service account

---

## Usage

```hcl
module "gcp_alloydb" {
  source = "../../modules/database/gcp_alloyDB"

  project_id = "my-project-id"
  region     = "us-central1"

  tags = {
    environment = "production"
    team        = "platform"
  }

  clusters = [
    {
      key     = "app-db"
      name    = "my-app-alloydb-prod"
      network = "projects/my-project-id/global/networks/my-vpc"

      automated_backup_enabled         = true
      continuous_backup_recovery_window = 14
      initial_password                 = "changeme"

      primary = {
        cpu_count         = 8
        availability_type = "REGIONAL"
        database_flags    = { "max_connections" = "500" }
      }

      read_pools = [
        {
          instance_id = "read-pool-1"
          cpu_count   = 4
          node_count  = 2
        }
      ]
    }
  ]
}
```

> **Destroy note**: Set `deletion_protection = false` on clusters before running `terraform destroy`.

---

## See Also

- [Service explainer](gcp-alloydb.md) — AlloyDB concepts, architecture, and connectivity guide
- [Deployment plan](../../../tf-plans/gcp_alloydb/README.md) — wrapper with `terraform.tfvars` examples
- [AlloyDB product documentation](https://cloud.google.com/alloydb/docs)
- [Terraform google_alloydb_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_cluster)
