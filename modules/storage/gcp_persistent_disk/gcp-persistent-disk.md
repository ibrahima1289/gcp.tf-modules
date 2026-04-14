# Google Persistent Disk

## Service overview

[Google Persistent Disk (PD)](https://cloud.google.com/compute/docs/disks) is durable, network-attached block storage for Compute Engine and GKE. Persistent disks are independent of the VM lifecycle — you can detach a disk from one instance and re-attach it to another, take snapshots for backup, or create new disks from snapshots. Google replicates data across multiple physical storage devices within a zone to provide durability.

Persistent Disk is the default block storage for most Compute Engine workloads. For very high IOPS or throughput requirements, consider [Hyperdisk](../gcp_hyperdisk/gcp-hyperdisk.md) instead.

---

## How Persistent Disk works

```text
VM Instance
  ├── Boot disk (persistent disk, auto-created from OS image)
  └── Additional data disk (persistent disk, attached as /dev/sdb, etc.)
        └── Lifecycle independent from VM — survives VM deletion
              └── Snapshots → backup to Cloud Storage, new disks, cross-region copies
```

---

## Disk types

| Type | Technology | IOPS (read/write) | Throughput | Best for |
|------|-----------|:-----------------:|-----------|----------|
| **pd-standard** | HDD | ~0.75 read / 1.5 write per GB | ~120 MB/s read | Sequential read, cold archives, infrequent-access data |
| **pd-balanced** | SSD | 6 read / 6 write per GB (max 80K/80K) | ~240 MB/s read | General-purpose production workloads, boot disks |
| **pd-ssd** | SSD | 30 read / 30 write per GB (max 100K/100K) | ~480 MB/s read | Higher IOPS databases, fast data layers |
| **pd-extreme** | SSD (provisioned) | Up to 120K/120K (set independently) | Up to 2,400 MB/s | High-performance OLTP, SAP HANA |

> `pd-extreme` is the only Persistent Disk type with independently provisioned IOPS (similar to Hyperdisk, but with lower max limits).

---

## Disk modes

| Mode | Description |
|------|-------------|
| **READ_WRITE** | Single VM can read and write (default for data disks) |
| **READ_ONLY** | Multiple VMs can mount the same disk for read-only access |
| **Zonal** | Disk resides in a single zone (default) |
| **Regional** | Disk synchronously replicated across 2 zones (HA, failover) |

---

## Snapshot capabilities

| Capability | Description |
|-----------|-------------|
| **Standard snapshot** | Point-in-time copy stored in Cloud Storage; incremental after first |
| **Instant snapshot** | Near-instant crash-consistent copy; stored in same zone; no GCS cost |
| **Snapshot schedule** | Automated snapshot policy (hourly/daily/weekly + retention window) |
| **Cross-region snapshot** | Copy snapshots to other regions for DR |
| **Disk cloning** | Create a new disk from a snapshot in any zone |

---

## When to use Persistent Disk

- Data must survive VM restarts, replacements, or terminations.
- Workloads need block-device semantics and full filesystem control.
- Boot or data disks require predictable durability without managing replication.
- You need snapshot-based backup and cloning.

---

## Core capabilities

- Balanced, Standard HDD, SSD, and Extreme-backed disk types.
- Independent lifecycle from attached instances; survives VM deletion.
- Snapshot-based backup, cloning, and cross-region copy workflows.
- Regional persistent disks for synchronous zone redundancy.
- Encryption with Google-managed or customer-managed keys.
- Resize online without VM downtime (expand only; no shrink).

---

## Real-world usage

- Boot disks for all Compute Engine VM types.
- Stateful databases and transactional application data.
- GKE StatefulSet-backed PersistentVolumeClaims.
- Read-only shared data disks for multi-reader workloads.
- Regional PD for HA database failover (replicated across zones).

---

## Security and operations guidance

- Encrypt data disks with CMEK for PII and regulated workloads.
- Match disk type to workload profile: pd-standard for cold data, pd-ssd/hyperdisk for hot OLTP.
- Define snapshot schedules and retention policies explicitly for each critical disk.
- Use regional PD for production databases requiring automatic zone failover.
- Monitor disk utilization; resize before I/O saturation occurs.
- Do not store ephemeral scratch data on persistent disks — use Local SSD instead.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | Creates a zonal persistent disk |
| [`google_compute_region_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_disk) | Creates a regional persistent disk (2-zone replication) |
| [`google_compute_attached_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | Attaches an existing disk to a VM |
| [`google_compute_snapshot`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_snapshot) | Creates a point-in-time snapshot |
| [`google_compute_resource_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy) | Defines a snapshot schedule policy |

---

## Related Docs

- [Persistent Disk Overview](https://cloud.google.com/compute/docs/disks)
- [Disk Types and Performance](https://cloud.google.com/compute/docs/disks/performance)
- [Snapshot Schedules](https://cloud.google.com/compute/docs/disks/scheduled-snapshots)
- [Hyperdisk (higher performance)](../gcp_hyperdisk/gcp-hyperdisk.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
