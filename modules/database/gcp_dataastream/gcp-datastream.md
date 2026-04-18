# Google Datastream

[Datastream](https://cloud.google.com/datastream/docs) is a serverless change data capture (CDC) and replication service that streams data from operational databases — MySQL, PostgreSQL, Oracle, SQL Server, and Salesforce — into Google Cloud in near real-time. It is commonly used to replicate data into BigQuery for analytics, Cloud Storage for archival, or Spanner/AlloyDB for cross-database synchronization.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Datastream reads database changes using the source engine's native replication mechanism (binary log for MySQL, logical replication slots for PostgreSQL, LogMiner for Oracle) and delivers them as structured events to a destination. No agents are required on the source database. A backfill operation brings existing historical data into the destination before switching to live CDC streaming.

| Capability | Description |
|------------|-------------|
| **Serverless** | No infrastructure to manage; pay per GB processed |
| **Supported sources** | MySQL, PostgreSQL, Oracle, SQL Server (preview), Salesforce (preview) |
| **Supported destinations** | BigQuery, Cloud Storage, Spanner (preview) |
| **CDC mechanisms** | MySQL binlog, PostgreSQL logical replication, Oracle LogMiner |
| **Schema evolution** | Automatic schema detection and propagation |
| **Backfill** | Initial full-table load before CDC begins |
| **Private connectivity** | VPC peering or reverse SSH tunnel for private source databases |
| **Latency** | Typically under 60 seconds end-to-end |

---

## Core Concepts

### Stream Pipeline

```text
Source Database
  (MySQL / PostgreSQL / Oracle)
        │
        │  CDC (binlog / WAL / LogMiner)
        ▼
  Datastream Stream
        │
        │  Change events (INSERT / UPDATE / DELETE)
        ▼
  Destination
  (BigQuery / Cloud Storage / Spanner)
```

### Connection Profiles

A **connection profile** stores credentials and connectivity settings for a source or destination:

| Profile Type | Description |
|--------------|-------------|
| Source profile | Host, port, credentials for the source DB |
| Destination profile | Target dataset/bucket, format settings |

Connection profiles are reusable across multiple streams.

### Private Connectivity Options

| Method | Description | Use Case |
|--------|-------------|----------|
| **VPC peering** | Direct VPC peering between Datastream and source VPC | Cloud-hosted source databases |
| **Reverse SSH tunnel** | Outbound SSH tunnel from source to Datastream | On-premises or restricted environments |
| **IP allowlist** | Datastream's public IPs added to source firewall | Simple public-IP-accessible sources |
| **Forward SSH tunnel** | Bastion host forwarding | Locked-down source environments |

---

## Source Configuration

### MySQL

Requirements:
- Binary logging enabled (`binlog_format = ROW`)
- `binlog_row_image = FULL`
- Replication user with `REPLICATION SLAVE`, `REPLICATION CLIENT`, `SELECT` privileges

```sql
CREATE USER 'datastream'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'datastream'@'%';
```

### PostgreSQL

Requirements:
- Logical replication enabled (`wal_level = logical`)
- Replication user with `REPLICATION` attribute
- Publication created for the tables to stream

```sql
CREATE USER datastream WITH REPLICATION LOGIN PASSWORD 'password';
CREATE PUBLICATION datastream_pub FOR ALL TABLES;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO datastream;
```

### Oracle

Requirements:
- LogMiner enabled; `SUPPLEMENTAL_LOG_DATA_ALL` enabled
- Archivelog mode enabled
- Dedicated replication user with LogMiner and SELECT privileges

---

## Destination: BigQuery

When streaming to BigQuery, Datastream creates or updates the target table schema automatically. CDC events are merged into BigQuery tables in near real-time.

| Setting | Description |
|---------|-------------|
| Dataset | Target BigQuery dataset |
| Table prefix | Optional prefix prepended to replicated table names |
| Merge mode | Full merge (upserts deletes) or append-only |

> Use **BigQuery Omni** or **cross-region datasets** when the source and destination regions differ to minimise egress costs.

---

## Destination: Cloud Storage

Datastream writes CDC events as Avro or JSON files to Cloud Storage. Downstream consumers (Dataflow, Spark, etc.) can process these files for custom transformations.

```text
gs://my-bucket/datastream/
  └── my-stream/
      └── mysql/
          └── my_database/
              └── my_table/
                  └── 2026-04-17T12:00:00_00000.avro
```

---

## Terraform Resources

```hcl
resource "google_datastream_connection_profile" "source" {
  display_name          = "MySQL Source"
  location              = "us-central1"
  connection_profile_id = "mysql-source"

  mysql_profile {
    hostname = "10.0.0.5"
    port     = 3306
    username = "datastream"
    password = "changeme"
  }
}

resource "google_datastream_stream" "stream" {
  display_name = "MySQL to BigQuery"
  location     = "us-central1"
  stream_id    = "mysql-to-bq"

  source_config {
    source_connection_profile = google_datastream_connection_profile.source.id
    mysql_source_config {}
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bq_dest.id
    bigquery_destination_config {
      single_target_dataset {
        dataset_id = "${var.project_id}:${google_bigquery_dataset.dest.dataset_id}"
      }
    }
  }

  backfill_all {}
}
```

---

## Security Guidance

- Use **VPC peering** or **reverse SSH tunnels** for production sources — never expose database ports publicly.
- Store source credentials in [Secret Manager](../gcp_secret_manager/gcp-secret-manager.md) and reference them at apply time.
- Create a **dedicated replication user** with minimum required privileges; avoid root/admin users.
- Enable **Data Access audit logs** on the Datastream API in Cloud Audit Logs.
- Use **VPC Service Controls** to restrict Datastream to a trusted perimeter when handling regulated data.

---

## Related Docs

- [Datastream Documentation](https://cloud.google.com/datastream/docs)
- [Datastream Pricing](https://cloud.google.com/datastream/pricing)
- [MySQL Source Configuration](https://cloud.google.com/datastream/docs/configure-your-source-mysql-database)
- [PostgreSQL Source Configuration](https://cloud.google.com/datastream/docs/configure-your-source-postgresql-database)
- [google_datastream_stream](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/datastream_stream)
- [google_datastream_connection_profile](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/datastream_connection_profile)
