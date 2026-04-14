# Google Hyperdisk

## Service overview

[Google Hyperdisk](https://cloud.google.com/compute/docs/disks/hyperdisks) is Google Cloud's next-generation block storage family for Compute Engine. Unlike Persistent Disk, Hyperdisk decouples capacity from performance — you independently provision IOPS and throughput without changing disk size. This makes it well-suited for databases, analytics engines, and latency-sensitive applications that have previously required over-provisioned SSD disks to hit performance targets.

---

## How Hyperdisk works

Hyperdisk is attached to Compute Engine VMs (and GKE nodes) as a block device, just like Persistent Disk. The key difference is the performance provisioning model:

```text
VM Instance
  └── Hyperdisk Volume
        ├── Capacity: 2 TB
        ├── Provisioned IOPS: 160,000   (set independently)
        └── Provisioned Throughput: 2,400 MB/s  (set independently)
```

Performance can be dynamically adjusted without detaching or rebooting the VM.

---

## Hyperdisk types

| Type | Max IOPS | Max Throughput | Max Capacity | Best for |
|------|:--------:|:--------------:|:------------:|----------|
| **Hyperdisk Balanced** | 160,000 | 2,400 MB/s | 64 TB | General-purpose databases, balanced workloads |
| **Hyperdisk Extreme** | 350,000 | 5,000 MB/s | 64 TB | Very high IOPS OLTP, SAP HANA scale-up |
| **Hyperdisk Throughput** | 7,500 | 1,200 MB/s | 32 TB | Sequential throughput workloads, Kafka, large scans |
| **Hyperdisk ML** | N/A (sequential read) | 1,200 MB/s per disk | 32 TB | ML training data loading, read-heavy AI pipelines |

> Performance limits are per-disk; VM-level limits also apply (check machine type disk caps).

---

## Performance tuning

| Parameter | Description |
|-----------|-------------|
| **Provisioned IOPS** | Set the IOPS target independently of disk size |
| **Provisioned throughput** | Set MB/s target independently of size or IOPS |
| **Dynamic resize** | Expand capacity online without VM downtime |
| **Dynamic performance update** | Adjust IOPS/throughput without detaching the disk |

---

## Hyperdisk vs Persistent Disk

| Dimension | Hyperdisk | Persistent Disk (SSD) |
|-----------|-----------|----------------------|
| Performance model | Independent IOPS/throughput provisioning | Tied to disk size |
| Max IOPS | Up to 350,000 | Up to 100,000 (pd-extreme) |
| Max throughput | Up to 5,000 MB/s | Up to 1,200 MB/s |
| Dynamic performance | Yes (without detach) | No |
| Best for | High-performance production databases | General VM workloads |

---

## When to use Hyperdisk

- Workloads require tunable disk performance independently from capacity.
- Databases need consistent low-latency storage (OLTP, SAP HANA, Cassandra).
- Standard Persistent Disk profiles cannot meet sustained throughput or IOPS demands.
- You want to right-size performance separately from storage capacity.

---

## Core capabilities

- Profile-based performance tiers (Balanced, Extreme, Throughput, ML).
- Independent, dynamic IOPS and throughput provisioning.
- Live performance updates without VM downtime or disk detach.
- Tight integration with Compute Engine and GKE.
- Snapshot support for backup and DR workflows.

---

## Real-world usage

- High-transaction OLTP systems (MySQL, PostgreSQL, SQL Server on large VM types).
- SAP HANA and enterprise ERP databases on M-series VMs.
- Kafka brokers requiring sequential write throughput without IOPS waste.
- ML training with large dataset reads (Hyperdisk ML for AI/ML pipelines).
- Throughput-intensive analytics engines with large sequential scan patterns.

---

## Security and operations guidance

- Encrypt disks with customer-managed keys (CMEK via Cloud KMS) for regulated workloads.
- Benchmark your workload baseline before selecting the Hyperdisk type and provisioned performance.
- Monitor IOPS utilization and throughput against provisioned values; adjust dynamically if nearing limits.
- Isolate critical database storage paths from general-purpose application disks.
- Take scheduled snapshots and store in a separate project for disaster recovery isolation.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | Creates a Hyperdisk volume (set `type = "hyperdisk-balanced"`, etc.) |
| [`google_compute_attached_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | Attaches an existing disk to a VM |
| [`google_compute_snapshot`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_snapshot) | Creates a point-in-time snapshot for backup |
| [`google_compute_resource_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy) | Schedules automated snapshots |

---

## Related Docs

- [Hyperdisk Overview](https://cloud.google.com/compute/docs/disks/hyperdisks)
- [Hyperdisk Types and Performance](https://cloud.google.com/compute/docs/disks/hyperdisks#hyperdisk-overview)
- [Persistent Disk vs Hyperdisk](../gcp_persistent_disk/gcp-persistent-disk.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
