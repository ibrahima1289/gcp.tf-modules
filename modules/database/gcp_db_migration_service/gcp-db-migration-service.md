# Google Database Migration Service (DMS)

[Database Migration Service (DMS)](https://cloud.google.com/database-migration/docs) is a managed service for migrating relational databases to Google Cloud with minimal downtime. It supports homogeneous migrations (e.g. MySQL → Cloud SQL for MySQL) and heterogeneous migrations (e.g. Oracle → AlloyDB, SQL Server → Cloud SQL for PostgreSQL). DMS handles schema conversion, initial data load, and continuous replication so the source remains operational until cutover.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

A DMS **migration job** reads data from the source using CDC replication, loads it into the destination, and keeps both in sync until you promote the destination to primary. DMS is built on top of Datastream for CDC and uses database-native replication protocols (binlog, WAL) under the hood. For heterogeneous migrations, the [Database Migration Service Schema Conversion Tool](https://cloud.google.com/database-migration/docs/schema-conversion-tool) (or **Ora2Pg** for Oracle) assists in transforming source DDL to the target dialect.

| Capability | Description |
|------------|-------------|
| **Homogeneous migrations** | MySQL → Cloud SQL MySQL, PostgreSQL → Cloud SQL PostgreSQL, PostgreSQL → AlloyDB |
| **Heterogeneous migrations** | Oracle → AlloyDB, Oracle → Cloud SQL PostgreSQL, SQL Server → Cloud SQL PostgreSQL |
| **Minimal downtime** | Continuous replication keeps source and destination in sync until cutover |
| **Schema conversion** | Integrated Schema Conversion Tool for DDL transformation |
| **Private connectivity** | VPC peering, reverse SSH tunnel, or IP allowlist |
| **Serverless** | No infrastructure to manage; pay per GB migrated |
| **Free tier** | Homogeneous migrations to Cloud SQL are free; heterogeneous migrations billed per GB |

---

## Core Concepts

### Migration Job Lifecycle

```text
1. Create connection profiles (source + destination)
        ↓
2. Create migration job (CONTINUOUS or ONE_TIME)
        ↓
3. Verify prerequisites (DMS checks source config)
        ↓
4. Start migration job (full dump → CDC streaming)
        ↓
5. Monitor lag until replication is caught up
        ↓
6. Promote destination (cutover; source goes read-only)
```

### Migration Types

| Type | Description | Use Case |
|------|-------------|----------|
| `CONTINUOUS` | Full dump + ongoing CDC replication until promoted | Minimal-downtime migrations |
| `ONE_TIME` | Single full dump with no CDC | Acceptable downtime; dev/test migrations |

### Connection Profiles

A **connection profile** stores credentials for a source database or a Cloud SQL / AlloyDB destination. Profiles are reusable across multiple migration jobs.

### Private Connectivity

| Method | Description |
|--------|-------------|
| **VPC peering** | Recommended for Cloud-hosted sources |
| **Reverse SSH tunnel** | For on-premises or network-restricted sources |
| **IP allowlist** | DMS static IPs added to source firewall rules |

---

## Supported Source → Destination Paths

| Source | Destination | Type |
|--------|-------------|------|
| MySQL 5.6 / 5.7 / 8.0 | Cloud SQL for MySQL | Homogeneous |
| PostgreSQL 9.4–16 | Cloud SQL for PostgreSQL | Homogeneous |
| PostgreSQL 9.4–16 | AlloyDB for PostgreSQL | Homogeneous |
| Oracle 11g–19c | AlloyDB for PostgreSQL | Heterogeneous |
| Oracle 11g–19c | Cloud SQL for PostgreSQL | Heterogeneous |
| SQL Server 2008–2022 | Cloud SQL for PostgreSQL | Heterogeneous |

---

## Schema Conversion Tool

For heterogeneous migrations, the Schema Conversion Tool:
1. Connects to the source and extracts DDL (tables, views, indexes, sequences, stored procedures, functions, triggers).
2. Converts each object to the target dialect, flagging items that require manual review.
3. Generates a conversion report with a risk score per object.
4. Applies converted schema to the destination with one click.

Objects that cannot be auto-converted (e.g. Oracle packages, complex PL/SQL) are flagged with suggested alternatives.

---

## Source Prerequisites

### MySQL

```sql
-- Enable binary logging (set in my.cnf)
-- binlog_format = ROW
-- binlog_row_image = FULL

CREATE USER 'dms'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'dms'@'%';
```

### PostgreSQL

```sql
-- wal_level = logical  (set in postgresql.conf)

CREATE USER dms REPLICATION LOGIN PASSWORD 'password';
CREATE PUBLICATION dms_pub FOR ALL TABLES;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dms;
```

### Oracle (Heterogeneous)

- Enable ARCHIVELOG mode
- Enable `SUPPLEMENTAL_LOG_DATA_ALL`
- Grant DMS user `LOGMINING`, `SELECT ANY TABLE`, `SELECT_CATALOG_ROLE`

---

## Terraform Resources

```hcl
resource "google_database_migration_service_connection_profile" "source" {
  location              = "us-central1"
  connection_profile_id = "mysql-source"
  display_name          = "MySQL Source"

  mysql {
    host     = "10.0.0.5"
    port     = 3306
    username = "dms"
    password = "changeme"
  }
}

resource "google_database_migration_service_migration_job" "job" {
  location         = "us-central1"
  migration_job_id = "mysql-to-cloudsql"
  display_name     = "MySQL to Cloud SQL"
  type             = "CONTINUOUS"

  source      = google_database_migration_service_connection_profile.source.name
  destination = google_database_migration_service_connection_profile.dest.name
}
```

---

## Monitoring Migration Progress

Track migration lag in the console or via Cloud Monitoring:

| Metric | Description |
|--------|-------------|
| `migration_job/replication_lag` | Seconds the destination is behind the source |
| `migration_job/full_dump_progress` | Percentage of initial dump completed |
| `migration_job/state` | Current state: RUNNING, STOPPED, FAILED, COMPLETED |

Use `migration_job/replication_lag < 60` as the signal that the destination is ready for cutover.

---

## Security Guidance

- Create a **dedicated migration user** on the source with minimum required privileges; revoke after migration.
- Store source credentials in [Secret Manager](../gcp_secret_manager/gcp-secret-manager.md); reference at connection profile creation time.
- Use **VPC peering** or **reverse SSH tunnels** — never expose source database ports publicly.
- Enable **Cloud Audit Logs** (`DATA_READ`, `DATA_WRITE`) on the DMS API.
- Validate the migration in a **test run** against a non-production clone before migrating production.
- Plan a **rollback window**: keep the source database running in read-only mode for at least 24 hours after cutover.

---

## Related Docs

- [Database Migration Service Documentation](https://cloud.google.com/database-migration/docs)
- [DMS Pricing](https://cloud.google.com/database-migration/pricing)
- [Schema Conversion Tool](https://cloud.google.com/database-migration/docs/schema-conversion-tool)
- [MySQL Migration Guide](https://cloud.google.com/database-migration/docs/mysql/quickstart)
- [PostgreSQL Migration Guide](https://cloud.google.com/database-migration/docs/postgres/quickstart)
- [google_database_migration_service_migration_job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/database_migration_service_migration_job)
