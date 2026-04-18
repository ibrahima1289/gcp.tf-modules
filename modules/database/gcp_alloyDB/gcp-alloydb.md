# Google AlloyDB for PostgreSQL

[AlloyDB for PostgreSQL](https://cloud.google.com/alloydb/docs) is a fully managed, PostgreSQL-compatible database service engineered for demanding transactional and analytical workloads. It uses a disaggregated storage-compute architecture — separating the query-processing layer from a distributed, log-structured storage layer — to deliver significantly higher throughput and lower latency than standard PostgreSQL deployments while remaining fully wire-compatible with PostgreSQL 14+.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

AlloyDB separates the database into a **primary instance** (read/write), optional **read pool instances** (scale-out reads), and a **columnar engine cache** for in-memory analytics. The storage layer replicates data across multiple zones automatically; the primary instance does not need a manually provisioned standby — HA failover is built into the storage tier.

| Capability | Description |
|------------|-------------|
| **PostgreSQL compatibility** | Wire-compatible with PostgreSQL 14+; supports extensions |
| **High availability** | Automatic zone-level failover without a separate standby VM |
| **Read pools** | Horizontally scalable read instances for read-heavy workloads |
| **Columnar engine** | In-memory columnar cache for accelerated analytical queries |
| **AI / ML integration** | Built-in `google_ml_integration` for calling Vertex AI from SQL |
| **Continuous backups** | PITR with 35-day retention; near-zero RPO |
| **Private IP only** | Accessible exclusively via VPC Private Service Access |
| **Managed upgrades** | In-place major version upgrades without instance recreation |

---

## Core Concepts

### Architecture

```text
Client Application
      │
      ▼
AlloyDB Primary Instance  (read/write, PostgreSQL-compatible)
      │
      ├── Read Pool Instance(s)  (scale-out reads; same cluster)
      │
      └── Distributed Storage Layer
            ├── Replica 1 (zone A)
            ├── Replica 2 (zone B)
            └── Replica 3 (zone C)
```

### Cluster and Instance Model

| Resource | Description |
|----------|-------------|
| **Cluster** | Top-level container; holds all instances and databases; bound to a VPC and region |
| **Primary instance** | Single read/write instance; serves all DML operations |
| **Read pool instance** | One or more read-only instances in the same cluster; load-balanced automatically |
| **Secondary cluster** | Cross-region replica cluster for disaster recovery |

### Machine Types

AlloyDB uses custom vCPU + memory sizing:

| vCPU | RAM | Notes |
|------|-----|-------|
| 2 | 16 GB | Development / light workloads |
| 4 | 32 GB | Small production |
| 8 | 64 GB | Medium production |
| 16 | 128 GB | Large production |
| 64 | 512 GB | Very large / analytics |

### Columnar Engine

The columnar engine stores a columnar projection of hot tables in memory alongside the row store. Queries that can use the columnar cache are automatically routed to it — no query rewriting required.

```sql
-- Enable columnar engine on a table
ALTER TABLE orders SET (alloydb_columnar_cache = on);

-- Check which queries used the columnar engine
SELECT * FROM pg_stat_alloydb_columnar;
```

### AI / ML Integration

AlloyDB integrates with Vertex AI to call ML models directly from SQL:

```sql
SELECT google_ml.predict_row(
  model_id => 'text-bison@001',
  input    => json_build_object('prompt', description)
) FROM products;
```

---

## Connectivity

AlloyDB instances are **private IP only** — they require [Private Service Access](https://cloud.google.com/alloydb/docs/configure-connectivity) to be configured on the VPC. Public IP connectivity is not supported.

```text
App VPC  ──── Private Service Access peering ────  AlloyDB VPC (Google-managed)
```

The [AlloyDB Auth Proxy](https://cloud.google.com/alloydb/docs/auth-proxy/overview) provides the same IAM-gated encrypted tunnel as the Cloud SQL Auth Proxy.

---

## Backup and Recovery

| Feature | Description |
|---------|-------------|
| **Continuous backups** | Enabled by default; retain up to 35 days |
| **On-demand backups** | Manually triggered; retained until deleted |
| **Point-in-time recovery** | Restore cluster to any second within the retention window |
| **Cross-region backups** | Copy backups to another region for compliance |

---

## AlloyDB vs Cloud SQL — When to Choose

| Factor | Cloud SQL | AlloyDB |
|--------|-----------|---------|
| PostgreSQL compatibility | ✅ | ✅ (wire-compatible) |
| Transactional throughput | Good | 4× higher (Google benchmark) |
| Analytical queries | Standard | Columnar cache acceleration |
| Public IP support | ✅ | ❌ (private IP only) |
| MySQL / SQL Server | ✅ | ❌ (PostgreSQL only) |
| Pricing model | Per vCPU + storage | Per vCPU + storage + replication |
| Best for | General relational workloads | High-throughput transactional + HTAP |

---

## Security Guidance

- AlloyDB is **private IP only** — ensure Private Service Access is configured on the VPC before creating a cluster.
- Use **IAM database authentication** (`google_alloydb_user` with `CLOUD_IAM_SERVICE_ACCOUNT`) for application workloads.
- Enable **CMEK** (`encryption_config`) for clusters storing regulated data.
- Grant `roles/alloydb.client` to application service accounts; avoid `roles/alloydb.admin`.
- Enable **Data Access audit logs** in Cloud Audit Logs for `DATA_READ` and `DATA_WRITE`.

---

## Related Docs

- [AlloyDB Documentation](https://cloud.google.com/alloydb/docs)
- [AlloyDB Pricing](https://cloud.google.com/alloydb/pricing)
- [AlloyDB Auth Proxy](https://cloud.google.com/alloydb/docs/auth-proxy/overview)
- [AlloyDB vs Cloud SQL](https://cloud.google.com/blog/products/databases/alloydb-for-postgresql-vs-cloud-sql-for-postgresql)
- [google_alloydb_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_cluster)
- [google_alloydb_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_instance)
