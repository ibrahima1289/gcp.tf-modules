# Google Cloud Spanner

[Cloud Spanner](https://cloud.google.com/spanner/docs) is a fully managed, horizontally scalable, globally distributed relational database with strong external consistency. It combines the transactional guarantees of a relational database with the horizontal scalability of a NoSQL system — making it suitable for globally deployed applications that require both ACID transactions and high throughput.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Cloud Spanner instances consist of one or more **nodes** (or **processing units**) distributed across chosen regions. Data is automatically sharded into **splits**, replicated synchronously across all replicas, and consistent reads are guaranteed using Google's TrueTime API. Applications interact with Spanner via client libraries (Go, Java, Python, Node.js, etc.) or through the REST/gRPC APIs. A PostgreSQL-compatible interface is also available.

| Capability | Description |
|------------|-------------|
| **Global distribution** | Multi-region instances with synchronous replication |
| **Strong consistency** | Linearizable reads and serializable read-write transactions |
| **Horizontal scaling** | Add nodes/processing units without downtime |
| **ACID transactions** | Full read-write and read-only transaction support |
| **SQL interface** | Standard SQL (GoogleSQL dialect) and PostgreSQL dialect |
| **Managed backups** | Scheduled and on-demand backups with cross-region support |
| **Change streams** | CDC-style stream of data mutations for downstream consumers |
| **IAM integration** | Fine-grained database-level IAM roles |

---

## Core Concepts

### Instance Configuration

An instance configuration defines the geographic placement of replicas:

| Config Type | Description | Use Case |
|-------------|-------------|----------|
| **Regional** | All replicas in one region (3 zones) | Low latency single-region apps |
| **Multi-region** | Replicas spread across multiple regions | Global apps; higher availability SLA |
| **Dual-region** | Two specific regions | Compliance-driven data residency |

### Processing Units vs Nodes

| Unit | Description |
|------|-------------|
| **Processing Unit (PU)** | Minimum: 100 PU; fractional compute; for smaller workloads |
| **Node** | 1 node = 1000 PU; used for larger production workloads |

> Start with 100–300 PU for development and scale up. Each node provides approximately 2 TB of storage capacity.

### Interleaved Tables

Spanner supports interleaved (co-located) child tables for parent-child data that is frequently accessed together:

```sql
CREATE TABLE Albums (
  SingerId   INT64 NOT NULL,
  AlbumId    INT64 NOT NULL,
  Title      STRING(MAX),
) PRIMARY KEY (SingerId, AlbumId),
  INTERLEAVE IN PARENT Singers ON DELETE CASCADE;
```

Interleaved tables eliminate cross-split joins for common access patterns, dramatically reducing read latency.

### Change Streams

Change streams capture a continuous feed of inserts, updates, and deletes on selected tables:

```sql
CREATE CHANGE STREAM NamesAndAlbums
  FOR Singers(FirstName, LastName), Albums;
```

Downstream consumers (Dataflow, Pub/Sub pipelines) can subscribe to these changes for CDC, auditing, and event-driven architectures.

---

## Consistency Model

Spanner uses **external consistency** (stronger than serializable): every committed transaction appears to have occurred at a real wall-clock time, enforced using atomic clocks and GPS receivers (TrueTime).

| Read Type | Description |
|-----------|-------------|
| **Strong read** | Most recent committed data; uses external consistency |
| **Stale read** | Data at a specific timestamp; lower latency, potential stale data |
| **Read-only transaction** | Consistent snapshot across multiple reads |
| **Read-write transaction** | Full ACID; uses two-phase locking + TrueTime commit wait |

---

## Backups

| Feature | Description |
|---------|-------------|
| **Scheduled backups** | Automated backups with configurable retention (up to 1 year) |
| **On-demand backups** | Manually triggered; persist until explicitly deleted |
| **Cross-region copy** | Copy backups to another region for DR |
| **Restore** | Restore to a new database; cannot restore in-place |

---

## Security Guidance

- Grant `roles/spanner.databaseUser` to application service accounts; avoid `roles/spanner.admin`.
- Use **VPC Service Controls** to restrict Spanner access to trusted VPC perimeters.
- Enable **Data Access audit logs** (`DATA_READ`, `DATA_WRITE`) in Cloud Audit Logs.
- Use **Customer-Managed Encryption Keys (CMEK)** for databases with regulatory requirements.
- Prefer **IAM conditions** to scope database roles to specific databases or time windows.

---

## Related Docs

- [Cloud Spanner Documentation](https://cloud.google.com/spanner/docs)
- [Cloud Spanner Pricing](https://cloud.google.com/spanner/pricing)
- [Choosing Between Cloud SQL and Spanner](https://cloud.google.com/blog/topics/developers-practitioners/cloud-sql-vs-cloud-spanner-choosing-right-database)
- [Change Streams Overview](https://cloud.google.com/spanner/docs/change-streams/overview)
- [google_spanner_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_instance)
