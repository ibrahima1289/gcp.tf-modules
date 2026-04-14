# Google Backup and DR Service

## Service overview

[Google Backup and DR Service](https://cloud.google.com/backup-disaster-recovery/docs) is a fully managed data protection platform that provides centralized backup, recovery, and disaster recovery orchestration for hybrid and cloud-native workloads. It replaces traditional agent-based backup software with a policy-driven, application-aware backup management system.

The service uses a **management server** hosted by Google and **backup/recovery appliances** deployed in your VPC to capture application-consistent backups of VMs, databases, and file systems.

---

## How Backup and DR Service works

```text
Workload (VM, Database, File System)
      |
Backup/Recovery Appliance (in your VPC)
  ├── Application-consistent snapshot
  ├── Deduplication and compression
  └── Encrypted transfer to Backup Vault
        |
Backup Vault (isolated, tamper-evident storage project)
  ├── Immutable retention enforcement (WORM-style)
  └── Cross-region copy (optional DR)
        |
Management Server (Google-managed control plane)
  └── Policy authoring, job scheduling, restore orchestration
```

---

## Supported workload types

| Workload | Protection mechanism |
|----------|---------------------|
| **Compute Engine VMs** | Application-consistent, incremental-forever backups |
| **VMware Engine (GCVE)** | VM-level and vSphere-aware backups |
| **Cloud SQL** | Backup integration with Cloud SQL snapshot capability |
| **SAP HANA** | Application-consistent database backups using SAP APIs |
| **Oracle Database** | RMAN-integrated incremental backup support |
| **Microsoft SQL Server** | VSS-aware database and log backups |
| **File systems (NFS/SMB)** | Filesystem-level file and folder backups |
| **MySQL / PostgreSQL** | Database-consistent snapshots via agent integration |

---

## Backup concepts

| Concept | Description |
|---------|-------------|
| **Backup plan** | Policy defining schedule (hourly/daily/weekly), retention period, and vault destination |
| **Backup vault** | Isolated, tamper-resistant storage location for backups; separate from workload projects |
| **Immutability** | Backup vault enforces minimum retention — protected backups cannot be deleted until retention expires |
| **Backup job** | Single execution of a backup plan for a specific workload |
| **Recovery point** | A point-in-time backup image that can be mounted or restored |
| **Recovery job** | Restore operation that reconstructs a workload from a recovery point |
| **SLA policy** | Service level agreement target (RPO/RTO) monitored by the management server |

---

## RPO and RTO targets

| Term | Definition | Typical configuration |
|------|-----------|----------------------|
| **RPO** (Recovery Point Objective) | Maximum tolerable data loss (time since last backup) | Hourly for critical databases; daily for general VMs |
| **RTO** (Recovery Time Objective) | Maximum tolerable time to restore service | Instant mount (minutes) for critical; full restore (hours) for cold backups |

---

## Restore options

| Option | Speed | Description |
|--------|-------|-------------|
| **Instant mount** | Minutes | Mount the backup image directly and run from the backup copy |
| **Full restore** | Hours | Full copy of data to a new or existing volume/instance |
| **Granular restore** | Minutes–Hours | Recover individual files, folders, tables, or database items |
| **Cross-region restore** | Hours | Restore to a different region from a replicated backup copy |

---

## When to use Backup and DR

- Compliance requires formal backup retention policies with immutability guarantees.
- Workloads need tested recovery runbooks with defined RPO/RTO.
- Multiple teams need centralized protection governance from a single management plane.
- You operate hybrid environments (VMware + GCP) needing unified backup.

---

## Core capabilities

- Policy-based backup schedules and retention controls.
- Backup vault with immutable, tamper-evident storage.
- Centralized restore and disaster recovery orchestration.
- Protection across VMs, databases, SAP, Oracle, SQL Server, and filesystems.
- Operational visibility, SLA reporting, and alert integration.

---

## Real-world usage

- Regulated industries (financial, healthcare) with auditable retention requirements.
- SAP HANA and Oracle Database backup in a centralized, policy-driven framework.
- Cross-region disaster recovery planning for mission-critical systems.
- Centralized enterprise backup governance spanning multiple projects.
- Ransomware recovery using air-gapped vault immutability.

---

## Security and operations guidance

- Store backups in a dedicated Backup Vault project, separate from workload projects.
- Enable vault immutability to prevent accidental or malicious deletion before retention expires.
- Assign `roles/backupdr.backupOperator` and `roles/backupdr.restoreOperator` as least-privilege roles.
- Define and document RPO and RTO targets per workload tier before deploying backup plans.
- Schedule regular restore tests — untested backups provide false assurance.
- Separate backup plan authoring from backup deletion authority (different IAM roles).
- Replicate vaults to a secondary region for cross-region DR coverage.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_backup_dr_management_server`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/backup_dr_management_server) | Deploys the management server instance |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `backupdr.googleapis.com` API |
| [`google_service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) | Dedicated SA for backup appliance operations |

---

## Related Docs

- [Backup and DR Overview](https://cloud.google.com/backup-disaster-recovery/docs)
- [Backup Vault Concepts](https://cloud.google.com/backup-disaster-recovery/docs/concepts/backup-vaults)
- [Supported Workloads](https://cloud.google.com/backup-disaster-recovery/docs/concepts/supported-workloads)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
