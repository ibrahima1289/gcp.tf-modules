# Google Local SSD

## Service overview

[Google Local SSD](https://cloud.google.com/compute/docs/disks/local-ssd) is ephemeral, host-attached solid-state storage physically located on the server hosting your Compute Engine VM. Because it is directly attached to the physical host rather than over the network, Local SSD delivers significantly higher IOPS and lower latency than any network-attached option (Persistent Disk or Hyperdisk).

The trade-off is ephemerality: Local SSD data does not persist if the VM is stopped, the instance is live-migrated (in some cases), or the underlying host fails. Local SSD is exclusively for temporary data that can be recreated or replicated from durable storage.

---

## How Local SSD works

```text
Physical Host (server blade in Google data center)
  ├── VM (your instance)
  │     └── Local SSD partition(s) — e.g., /dev/nvme0n1
  └── [Data does NOT leave the physical host]
        └── Not replicated, not network-attached, not snapshotable
```

---

## Interface types

| Interface | Description | Performance |
|-----------|-------------|-------------|
| **NVMe** | PCIe-attached NVMe; available on most modern VM families | Highest: up to ~2.4 GB/s read throughput per partition |
| **SCSI** | Legacy interface option | Lower than NVMe; not recommended for new deployments |

> NVMe is strongly recommended for all new deployments.

---

## Partition sizes and VM limits

| Partition size | Partitions per VM (max) | Total raw capacity (max) |
|:--------------:|:-----------------------:|:------------------------:|
| **375 GB** | 24 | 9 TB |

Each Local SSD partition is 375 GB. You can attach multiple partitions and stripe them for higher aggregate IOPS:

- 1 partition → 375 GB, ~680K IOPS (NVMe)
- 4 partitions → 1.5 TB, ~2.4 M IOPS (striped)
- 24 partitions → 9 TB, max IOPS

---

## VM compatibility

| VM family | Local SSD support |
|-----------|------------------|
| **N1, N2, N2D** | Yes |
| **C2, C2D, C3** | Yes |
| **M1, M2, M3** | Yes |
| **A2, A3, G2** | Yes |
| **E2** | No |
| **T2D, T2A** | No |

> Local SSD is not available on E2, T2D, or T2A instances.

---

## Persistence behavior

| Event | Local SSD data |
|-------|---------------|
| **VM reboot** | ✅ Preserved |
| **VM stop** | ❌ Lost (unless using NVDIMM-backed experimental Local SSD) |
| **Live migration** | ✅ Preserved (best-effort for NVMe) |
| **Host failure / maintenance** | ❌ May be lost (no network replication) |

---

## When to use Local SSD

- Workloads need extremely fast scratch storage (caches, sort buffers, temporary files).
- Data can be regenerated, replicated, or rebuilt externally after a failure.
- Performance requirements exceed what Hyperdisk or Persistent Disk can deliver.
- Working sets for ML training data loading that fit in temporary fast storage.

---

## Core capabilities

- NVMe-backed, host-attached storage with very high IOPS and throughput.
- 375 GB partitions; up to 24 per VM (9 TB total).
- Lifecycle tied strictly to the VM host and instance.
- Suitable for temporary caches, shuffle space, and processing buffers.
- No snapshot, backup, or replication support.

---

## Real-world usage

- Redis or Memcached disk-backed cache acceleration layers.
- Temporary sort and shuffle space for Apache Spark, Hadoop, or BigQuery BI Engine.
- Low-latency buffer between ingestion and persistent storage in streaming pipelines.
- Transient working storage for video rendering or scientific simulation.
- GKE ephemeral volumes for short-lived high-throughput workloads.

---

## Security and operations guidance

- Treat Local SSD data as strictly transient; never store credentials, secrets, or PII.
- Keep the authoritative copy of all data in a durable storage service (GCS, PD, database).
- Implement application-level checkpointing and replication safeguards.
- Validate restart and rehydration behavior after host maintenance events.
- Use encryption at rest (Google manages Local SSD encryption automatically; no CMEK option).

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | Attach Local SSD via `scratch_disk` block with `interface = "NVME"` |
| [`google_compute_instance_template`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | Include `scratch_disk` blocks for MIG-backed fleets |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `compute.googleapis.com` API |

---

## Related Docs

- [Local SSD Overview](https://cloud.google.com/compute/docs/disks/local-ssd)
- [Local SSD Performance](https://cloud.google.com/compute/docs/disks/local-ssd#performance)
- [Persistent Disk (durable storage)](../gcp_persistent_disk/gcp-persistent-disk.md)
- [Hyperdisk (network-attached high performance)](../gcp_hyperdisk/gcp-hyperdisk.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
