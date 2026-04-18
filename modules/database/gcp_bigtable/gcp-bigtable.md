# Google Cloud Bigtable

[Cloud Bigtable](https://cloud.google.com/bigtable/docs) is a petabyte-scale, fully managed NoSQL wide-column database designed for low-latency, high-throughput workloads at massive scale. It powers several core Google services — including Search, Maps, and Gmail — and is the reference implementation of the original [Bigtable paper](https://research.google/pubs/pub27898/). Bigtable is the right choice when you need single-digit millisecond reads/writes at millions of operations per second on terabytes to petabytes of data.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

A Bigtable **instance** contains one or more **clusters** (each bound to a zone). A cluster contains **nodes** that serve requests; data is stored separately in Google's Colossus distributed file system — meaning storage scales independently of compute. Data is organized into **tables**, which contain **rows** keyed by a single row key, and each row contains **column families** (groups of related columns).

| Capability | Description |
|------------|-------------|
| **Scale** | Petabyte storage; millions of reads/writes per second |
| **Latency** | Sub-10 ms P99 at scale for random reads/writes |
| **Wide-column model** | Sparse, versioned column families; no fixed schema |
| **HBase compatibility** | HBase API compatible; easy migration from HBase workloads |
| **Replication** | Multi-cluster replication across zones/regions for HA and geo-proximity |
| **Autoscaling** | Node count adjusts automatically based on CPU utilization |
| **Managed backups** | Hot backups of table data with configurable retention |
| **Change Data Capture** | Integrated with Dataflow for streaming CDC pipelines |

---

## Core Concepts

### Data Model

```text
Table
└── Row (keyed by row_key)
    ├── Column Family: cf1
    │   ├── cf1:col_a  →  [ (timestamp_3, val3), (timestamp_2, val2), ... ]
    │   └── cf1:col_b  →  [ (timestamp_1, val1) ]
    └── Column Family: cf2
        └── cf2:metrics →  [ (timestamp_5, val5) ]
```

- **Row key**: the only index; all queries are by row key prefix or range scan.
- **Column family**: logical grouping of columns; garbage collection policies are per family.
- **Cell versions**: each cell stores multiple timestamped versions; older versions are garbage-collected per policy.

### Row Key Design

Row key design is the single most important performance decision in Bigtable. Poorly chosen keys cause **hotspots** — all traffic landing on a single node.

| Pattern | Use Case |
|---------|----------|
| `reverse_timestamp + user_id` | Time-series per user; most recent first |
| `user_id#event_type#timestamp` | Per-user event streams; scan by user prefix |
| `region#device_id` | Geo-sharded IoT telemetry |
| Hash prefix | Distribute writes evenly across nodes when natural key is sequential |

> **Avoid** monotonically increasing keys (timestamps, auto-increment IDs) as the sole row key — they create write hotspots on the last node.

### Column Families and Garbage Collection

Define a GC policy per column family:

```hcl
resource "google_bigtable_table" "events" {
  instance_name = google_bigtable_instance.main.name
  name          = "events"

  column_family {
    family = "raw"
    # Keep only the 3 most recent versions
    gc_policy = jsonencode({ "maxNumVersions" = 3 })
  }

  column_family {
    family = "aggregated"
    # Delete cells older than 30 days
    gc_policy = jsonencode({ "maxAge" = "720h" })
  }
}
```

---

## Instance Types

| Type | Description | Use Case |
|------|-------------|----------|
| `PRODUCTION` | Minimum 1 node; SLA-backed; replication available | All production workloads |
| `DEVELOPMENT` | Single node; no SLA; cheaper | Development and testing only |

### Node Count and Autoscaling

| Approach | Description |
|----------|-------------|
| Manual scaling | Fixed node count; predictable cost |
| Autoscaling | Min/max nodes + CPU target; adjusts within minutes |

> 1 node handles approximately 10 000 QPS for random reads or 10 000–100 000 QPS for scans. Node count and storage are independent.

---

## Replication

Multi-cluster replication synchronises data across clusters in different zones or regions:

| Replication Mode | Description |
|-----------------|-------------|
| **Async replication** | Default; eventual consistency between clusters |
| **Read routes** | Route reads to the nearest cluster using app profiles |
| **Failover** | Client retries automatically hit the secondary cluster |

App profiles control per-connection routing and consistency:

```hcl
resource "google_bigtable_app_profile" "read_profile" {
  instance       = google_bigtable_instance.main.name
  app_profile_id = "read-profile"
  multi_cluster_routing_use_any = true # route to nearest cluster
}
```

---

## Common Use Cases

| Use Case | Pattern |
|----------|---------|
| Time-series telemetry | Row key: `device_id#reverse_timestamp`; scan by prefix |
| User activity / event logs | Row key: `user_id#event_type#timestamp` |
| Recommendation features | Row key: `user_id`; columns = feature values |
| AdTech / clickstream | High-throughput appends; batch aggregation via Dataflow |
| Financial market data | Tick data keyed by `instrument#exchange#timestamp` |

---

## Security Guidance

- Grant `roles/bigtable.reader` to read-only workloads; `roles/bigtable.user` to read/write workloads; avoid `roles/bigtable.admin`.
- Use **CMEK** (`encryption_config`) for tables storing sensitive data.
- Use **VPC Service Controls** to restrict Bigtable to trusted service perimeters.
- Enable **Data Access audit logs** in Cloud Audit Logs.
- Never use `DEVELOPMENT` instances in production — they have no SLA and single-node failure is not tolerated.

---

## Related Docs

- [Bigtable Documentation](https://cloud.google.com/bigtable/docs)
- [Bigtable Pricing](https://cloud.google.com/bigtable/pricing)
- [Bigtable Schema Design](https://cloud.google.com/bigtable/docs/schema-design)
- [Bigtable vs Spanner vs Firestore](https://cloud.google.com/bigtable/docs/choosing-storage-option)
- [google_bigtable_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigtable_instance)
- [google_bigtable_table](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigtable_table)
