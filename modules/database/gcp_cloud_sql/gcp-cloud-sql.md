# Google Cloud SQL

Google Cloud SQL is a fully managed relational database service for [MySQL](https://cloud.google.com/sql/docs/mysql), [PostgreSQL](https://cloud.google.com/sql/docs/postgres), and [SQL Server](https://cloud.google.com/sql/docs/sqlserver). It handles database provisioning, patching, replication, failover, and backups so teams can focus on schema design and application logic rather than infrastructure operations.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md) · [Cloud SQL Module](./README.md)

---

## Overview

Cloud SQL instances run on Google-managed Compute Engine VMs with SSD or HDD persistent disks. Each instance is a single-region deployment that can be optionally promoted to a high-availability (HA) configuration with a standby replica in a second zone. Connections are made over public IP (with SSL), private IP via VPC peering (Private Service Access), or through the [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy) — a local sidecar that handles encrypted tunneling and IAM-based authentication without requiring firewall rules.

| Capability | Description |
|------------|-------------|
| **Engines** | MySQL 5.7 / 8.0, PostgreSQL 12–16, SQL Server 2017–2022 |
| **High availability** | Synchronous replication to a standby; automatic failover in 60–120 s |
| **Point-in-time recovery** | Restore to any second within the retention window |
| **Read replicas** | Cross-region replicas for read scaling and disaster recovery |
| **Private IP** | VPC-native connectivity via Private Service Access |
| **IAM database authentication** | Log in using Google identity tokens instead of passwords |
| **Cloud SQL Auth Proxy** | Encrypted, IAM-gated tunnel to any Cloud SQL instance |
| **Maintenance windows** | Controllable day/hour window for engine upgrades |

---

## Core Concepts

### Instance Tiers

Tiers define the CPU and memory allocation for the instance:

| Tier Pattern | Description |
|--------------|-------------|
| `db-f1-micro` | Shared-core; development/test only |
| `db-g1-small` | Shared-core; light workloads |
| `db-n1-standard-N` | Dedicated vCPUs; balanced |
| `db-n1-highmem-N` | High memory-to-CPU ratio |
| `db-custom-CPU-RAM` | Fully customisable vCPU + memory |
| `db-perf-optimized-N-*` | ENTERPRISE_PLUS edition; columnar cache + advanced analytics |

> `ENTERPRISE_PLUS` edition is required for SQL Server and enables additional performance features on MySQL/PostgreSQL.

### Availability Types

| Type | Description | Use Case |
|------|-------------|----------|
| `ZONAL` | Single zone; no automatic failover | Development, non-critical workloads |
| `REGIONAL` | Synchronous standby in a second zone; automatic failover | Production; SLA-sensitive workloads |

### Connectivity Options

```text
Application
  ├── Cloud SQL Auth Proxy  ──→  Instance (IAM auth, encrypted, no public IP needed)
  ├── Private IP (VPC)      ──→  Private Service Access peering
  └── Public IP + SSL       ──→  Authorized Networks CIDR allowlist
```

**Private Service Access** is the recommended approach for production: allocate a private IP range in the VPC, enable Service Networking API, then set `private_network` on the instance.

### SSL Modes

| Mode | Description |
|------|-------------|
| `ALLOW_UNENCRYPTED_AND_ENCRYPTED` | Accepts both SSL and non-SSL connections |
| `ENCRYPTED_ONLY` | Requires SSL; does not verify client certificate |
| `TRUSTED_CLIENT_CERTIFICATE_REQUIRED` | Requires SSL + valid client certificate (mutual TLS) |

### Backup and Recovery

| Feature | Description |
|---------|-------------|
| **Automated backups** | Daily snapshots stored in the same or a specified region |
| **Binary log (MySQL)** | Required for MySQL PITR; enables replay of individual transactions |
| **WAL-based PITR (PostgreSQL)** | Continuous WAL archiving; restore to any second in the retention window |
| **Retained backups** | Number of daily backup snapshots to keep (default 7) |
| **On-demand backups** | Triggered manually; not deleted automatically |
| **Cross-region backups** | Store backups in a different region for DR compliance |

### Database Flags

Engine-specific parameters set via `database_flags`:

```hcl
database_flags = [
  { name = "max_connections",             value = "200" },           # PostgreSQL
  { name = "log_min_duration_statement",  value = "500" },           # PostgreSQL
  { name = "slow_query_log",              value = "on" },            # MySQL
  { name = "innodb_buffer_pool_size",     value = "4294967296" },    # MySQL
]
```

### Query Insights

Query Insights provides visibility into database query performance without requiring additional agents:

| Setting | Description |
|---------|-------------|
| `insights_config_enabled` | Enable the feature |
| `query_string_length` | Max characters of query text captured (256–4500) |
| `record_application_tags` | Capture `application_name` / `pg_query_tags` |
| `record_client_address` | Capture originating IP address |
| `query_plans_per_minute` | Execution plan samples per minute (0–20) |

---

## IAM Database Authentication

Cloud SQL supports Google identity-based login for PostgreSQL and MySQL — no password required.

| User Type | `type` value | Description |
|-----------|-------------|-------------|
| Standard user | `BUILT_IN` | Password-based; created in the DB engine |
| Google account | `CLOUD_IAM_USER` | Logs in with a short-lived IAM token |
| Service account | `CLOUD_IAM_SERVICE_ACCOUNT` | Workload identity login |
| Cloud Identity group | `CLOUD_IAM_GROUP` | Group-based database access |

IAM users must also be granted `roles/cloudsql.instanceUser` on the project and the `cloudsqliamuser` database role on the instance.

---

## Maintenance and Lifecycle

### Maintenance Windows

Set `maintenance_window_day` (1=Monday … 7=Sunday) and `maintenance_window_hour` (UTC) to control when Google applies engine upgrades. Use `update_track = "stable"` to receive updates after early-adopter customers.

### Deletion Protection

`deletion_protection = true` prevents the instance from being destroyed via Terraform or the console. **Set to `false` before running `terraform destroy`.**

### Disk Autoresize

When `disk_autoresize = true`, Cloud SQL automatically increases disk capacity when utilisation exceeds 90%. Set `disk_autoresize_limit` to cap the maximum size (0 = unlimited).

---

## Read Replicas

Read replicas receive asynchronous replication from the primary instance and can serve read traffic to reduce load on the primary. Cross-region replicas also serve as the foundation for a manual failover DR strategy.

```hcl
# A cross-region read replica is defined as a separate instance
# with replica_configuration pointing to the primary.
# Not managed by this module directly — add a separate instances[] entry
# with database_version matching the primary.
```

---

## Security Guidance

- Use **private IP** (`private_network`) for all production instances; avoid public IP where possible.
- Set `ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"` for mutual TLS when public IP is required.
- Use **IAM database authentication** (`CLOUD_IAM_SERVICE_ACCOUNT`) for application workloads instead of storing passwords.
- Store built-in user passwords in [Secret Manager](../gcp_secret_manager/gcp-secret-manager.md), not in `terraform.tfvars`.
- Enable **audit logging** via `database_flags` (PostgreSQL `log_connections`, MySQL `general_log`) and route to Cloud Logging.
- Set `deletion_protection = true` on all production instances.
- Restrict `authorized_networks` to the minimum required CIDRs; prefer expiration times.

---

## Related Docs

- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Cloud SQL Pricing](https://cloud.google.com/sql/pricing)
- [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy)
- [Private Service Access for Cloud SQL](https://cloud.google.com/sql/docs/postgres/configure-private-services-access)
- [IAM Database Authentication](https://cloud.google.com/sql/docs/postgres/iam-authentication)
- [Cloud SQL Module → README](./README.md)
- [Cloud SQL Deployment Plan](../../../tf-plans/gcp_cloud_sql/README.md)
