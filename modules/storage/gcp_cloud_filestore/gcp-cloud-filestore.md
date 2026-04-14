# Google Cloud Filestore

## Service overview

[Google Cloud Filestore](https://cloud.google.com/filestore/docs) is a managed Network File System (NFS) service that delivers POSIX-compatible shared file storage for Linux workloads. Unlike object storage (GCS) or block storage (PD/Hyperdisk), Filestore provides a traditional mountable filesystem — multiple compute resources can simultaneously read and write the same directory tree using standard NFS mount semantics.

Filestore is the right choice when existing applications depend on shared file paths, NFS mounts, or POSIX-compliant filesystem APIs.

---

## How Cloud Filestore works

```text
Compute Engine VMs (or GKE nodes)
  ├── VM A: mount 10.x.x.x:/vol1 at /mnt/shared
  ├── VM B: mount 10.x.x.x:/vol1 at /mnt/shared  (concurrent access)
  └── VM C: mount 10.x.x.x:/vol1 at /mnt/shared
        |
Filestore Instance (NFS server, managed by Google)
  └── Volume /vol1 (e.g., 1 TB, Basic SSD tier)
        |
VPC network (Filestore sits inside your VPC via private IP)
```

---

## Service tiers

| Tier | Protocol | Min capacity | Max capacity | Max IOPS | Max throughput | Best for |
|------|----------|:------------:|:------------:|:--------:|:--------------:|----------|
| **Basic HDD** | NFSv3 | 1 TB | 63.9 TB | 60,000 | 180 MB/s | Low-cost file sharing, development |
| **Basic SSD** | NFSv3 | 2.5 TB | 63.9 TB | 60,000 | 1,200 MB/s | General production NFS, CI pipelines |
| **Zonal** | NFSv3, NFSv4.1 | 1 TB | 100 TB | 160,000 | 4,800 MB/s | High-performance single-zone workloads |
| **Regional** | NFSv3, NFSv4.1 | 1 TB | 100 TB | 320,000 | 4,800 MB/s | HA across two zones; production-critical |
| **Enterprise** | NFSv3, NFSv4.1 | 1 TB | 10 TB | 120,000 | 2,400 MB/s | Regulated, HA with 99.99% SLA, audit logging |

---

## Key capabilities

| Capability | Description |
|-----------|-------------|
| **NFSv3 / NFSv4.1** | Standard NFS protocol; compatible with Linux mount utilities |
| **Snapshots** | Point-in-time filesystem snapshots (automated or manual) |
| **Backups** | Filestore backups stored in Cloud Storage for DR workflows |
| **VPC peering** | Instance accessible via private IP in your VPC; no public exposure |
| **IAM** | Controls who can manage the Filestore instance; data access is via NFS exports |

---

## When to use Filestore

- Applications require shared file-system semantics and POSIX-compliant access.
- Lift-and-shift workloads depend on NFS paths and directory structures.
- Teams need managed shared file storage without server administration.
- GKE workloads require `ReadWriteMany` persistent volumes.

---

## Core capabilities

- Managed NFS shares with multiple performance tiers.
- Zonal and Regional options for resilient deployments.
- Tight integration with VPC networking and IAM.
- Snapshot and backup support for recovery workflows.
- Concurrent multi-client access from VMs and GKE nodes.

---

## Real-world usage

- Shared media and content repositories for rendering or publishing pipelines.
- Build artifact caches and CI pipeline shared workspace data.
- Legacy enterprise applications requiring NFS mounts.
- GKE persistent volumes needing `ReadWriteMany` (multiple pods writing simultaneously).
- Shared configuration and reference data for multi-VM fleets.

---

## Security and operations guidance

- Use VPC firewall rules to restrict NFS access (port 2049) to only the VMs that need it.
- Place Filestore and consuming compute in the same VPC to avoid peering complexity.
- Select the Regional tier for production-critical workloads requiring HA across zones.
- Define snapshot schedules and test restore procedures regularly.
- Use IAM roles (`roles/file.editor`, `roles/file.viewer`) to control management-plane access.
- Monitor IOPS and throughput utilization; resize the instance before saturation.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_filestore_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_instance) | Creates a Filestore instance with tier, capacity, and network settings |
| [`google_filestore_backup`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_backup) | Creates a manual backup of a Filestore instance |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `file.googleapis.com` API |

---

## Related Docs

- [Google Cloud Filestore Overview](https://cloud.google.com/filestore/docs)
- [Filestore Service Tiers](https://cloud.google.com/filestore/docs/service-tiers)
- [Filestore with GKE](https://cloud.google.com/filestore/docs/accessing-fileshares)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
