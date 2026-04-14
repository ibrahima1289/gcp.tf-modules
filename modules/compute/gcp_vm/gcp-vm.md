# Google Compute Engine (VM)

## Service overview

[Google Compute Engine (GCE)](https://cloud.google.com/compute/docs) is Google Cloud's Infrastructure-as-a-Service (IaaS) offering. It provides virtual machines (VMs) that run on Google's global infrastructure, giving you full control over the operating system, machine type, disk configuration, networking, startup scripts, and lifecycle management.

Unlike managed platforms such as Cloud Run or App Engine, Compute Engine gives you direct access to the underlying OS. You provision the resources, configure the runtime, and manage the software stack. This makes it the right choice for workloads that require deep customization, stateful data, legacy application compatibility, or predictable long-running compute.

---

## How Compute Engine VMs work

A VM in Compute Engine is created from a combination of:

- **Machine type** — determines vCPU and memory allocation
- **Boot disk** — the OS image, typically a persistent disk
- **Network interface** — VPC subnetwork, optional external IP
- **Service account** — identity the VM uses to call Google Cloud APIs
- **Metadata / startup scripts** — configuration applied at first boot
- **Labels and tags** — for governance, billing, and firewall targeting

VMs can be standalone instances, part of an **Instance Group** (unmanaged or managed), or launched from an **Instance Template** for repeatable fleet deployments.

---

## Machine families and types

Google Cloud organizes VM types into **machine families**, each tuned for a specific workload profile. Within each family there are **predefined series** with fixed vCPU/memory ratios and the option to create **custom machine types** with exact vCPU and memory values.

### Machine family overview

| Family | Series | Best for | vCPU range | Notes |
|--------|--------|----------|:----------:|-------|
| **General Purpose** | E2 | Cost-optimized, day-to-day workloads | 2 – 32 | Shared-core options available; good for dev/test |
| **General Purpose** | N2 | Balanced price/performance, production workloads | 2 – 128 | Intel Cascade/Ice Lake; custom sizing supported |
| **General Purpose** | N2D | AMD-based balanced workloads | 2 – 224 | AMD EPYC; cost-effective for large fleets |
| **General Purpose** | N4 | Latest-gen Intel balanced workloads | 2 – 208 | Intel Emerald Rapids; improved performance-per-dollar |
| **General Purpose** | T2D | Scale-out web/container workloads | 1 – 60 | AMD EPYC Milan; optimized for scale-out patterns |
| **General Purpose** | T2A | ARM-based scale-out workloads | 1 – 48 | Ampere Altra ARM; energy-efficient containerized loads |
| **Compute Optimized** | C2 | High-frequency single-threaded workloads | 4 – 60 | Intel Cascade Lake; gaming, HPC, EDA |
| **Compute Optimized** | C2D | High-throughput compute workloads | 2 – 112 | AMD EPYC Milan; better vCPU:memory ratio for compute-heavy jobs |
| **Compute Optimized** | C3 | Latest-gen compute-intensive workloads | 4 – 176 | Intel Sapphire Rapids; high-frequency processing |
| **Memory Optimized** | M1 | Large in-memory databases (SAP HANA, etc.) | 40 – 160 | Up to 3.75 TB RAM; certified for SAP HANA |
| **Memory Optimized** | M2 | Very large in-memory analytical workloads | 208 – 416 | Up to 11.7 TB RAM; ultra-high memory per vCPU |
| **Memory Optimized** | M3 | Latest-gen ultra-high-memory workloads | 32 – 128 | Up to 3.9 TB RAM; balanced memory/compute ratio |
| **Accelerator Optimized** | A2 | GPU workloads: ML training, HPC, rendering | 12 – 96 | NVIDIA A100 GPUs; high-bandwidth NVLink |
| **Accelerator Optimized** | A3 | Latest-gen GPU ML training | 52 – 208 | NVIDIA H100 GPUs; designed for large model training |
| **Accelerator Optimized** | G2 | GPU inference and graphics workloads | 4 – 96 | NVIDIA L4 GPUs; cost-efficient inference serving |

> Reference: [Google Cloud Machine Families](https://cloud.google.com/compute/docs/machine-resource)

---

## Shared-core and micro VMs

For very lightweight or intermittent workloads, Google Cloud offers shared-core VM types that time-share a physical CPU:

| Type | vCPU | Memory | Typical use |
|------|:----:|--------|-------------|
| `e2-micro` | 0.25 (burst to 2) | 1 GB | Development, low-traffic apps |
| `e2-small` | 0.5 (burst to 2) | 2 GB | Small background services |
| `e2-medium` | 1 (burst to 2) | 4 GB | Dev/test, CI runners |
| `f1-micro` | 0.2 (burst) | 0.6 GB | Legacy; lowest-cost always-free option |
| `g1-small` | 0.5 (burst) | 1.7 GB | Legacy lightweight workloads |

---

## Spot VMs (preemptible)

[Spot VMs](https://cloud.google.com/compute/docs/instances/spot) offer significantly reduced pricing (up to 91% discount) in exchange for the possibility of preemption when Google needs the capacity. They are suitable for:

- Batch jobs and data processing pipelines
- Fault-tolerant distributed workloads
- Cost-sensitive development and testing
- HPC and rendering jobs

Spot VMs have no minimum lifetime and can be preempted with a 30-second shutdown notice.

---

## Sole-tenant nodes

[Sole-tenant nodes](https://cloud.google.com/compute/docs/nodes/sole-tenant-nodes) provide physical servers dedicated exclusively to your workloads. Use cases include:

- Bring-your-own-license (BYOL) requirements (Windows Server, SQL Server)
- Compliance mandates requiring physical isolation
- Workloads with strict hardware affinity or performance isolation requirements

---

## Instance lifecycle states

| State | Description |
|-------|-------------|
| **PROVISIONING** | Resources are being allocated for the instance |
| **STAGING** | Instance is being prepared to run |
| **RUNNING** | Instance is running and ready |
| **STOPPING** | Instance is being stopped (graceful shutdown) |
| **TERMINATED** | Instance has stopped; disk data retained |
| **SUSPENDED** | Instance memory is preserved to disk (like hibernate) |
| **REPAIRING** | Instance is being repaired after a host maintenance event |

---

## When to use Compute Engine

- You need OS-level access, custom kernel parameters, or proprietary agents.
- You run stateful or legacy workloads not suited for containers or serverless.
- You require predictable, long-running compute with a reserved or committed profile.
- Your workload needs GPU, high memory, or specialized hardware attached.
- You lift-and-shift an on-premises application that depends on the VM model.

---

## Core capabilities

- Wide machine family selection from micro shared-core to 11+ TB memory VMs.
- Standard, SSD, Hyperdisk, and Local SSD storage attachment options.
- Shielded VMs, secure boot, vTPM, and integrity monitoring.
- Managed instance groups (MIGs) with autoscaling, autohealing, and rolling updates.
- Instance templates for repeatable, version-controlled fleet deployments.
- Live migration to maintain availability during host maintenance.

---

## Real-world usage

- Enterprise middleware, ERP, and monolithic application hosting.
- SAP HANA and large in-memory database deployments on M-series VMs.
- Bastion and jump-host access patterns in private VPCs.
- ML training jobs using A2/A3 GPU-attached instances.
- Background batch workers and CI/CD build agents.
- Windows Server and SQL Server BYOL workloads on sole-tenant nodes.

---

## Security and operations guidance

- Use least-privilege service accounts per workload; never use the default compute SA.
- Enforce OS patching baselines and hardening standards with OS Config.
- Disable unnecessary external IP assignment by default; use Cloud NAT for egress.
- Standardize deployments with instance templates and metadata startup scripts.
- Use managed instance groups with health checks for automatic self-healing.
- Schedule persistent disk snapshots and validate restore procedures regularly.
- Enable Shielded VM options (secure boot, vTPM, integrity monitoring) for sensitive workloads.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | Single VM instance |
| [`google_compute_instance_template`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | Reusable instance configuration for MIGs |
| [`google_compute_instance_group_manager`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager) | Managed instance group for autoscaling/autohealing |
| [`google_compute_region_instance_group_manager`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager) | Regional managed instance group for HA fleet deployments |
| [`google_compute_autoscaler`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler) | Autoscaling policy for a managed instance group |
| [`google_compute_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | Persistent disk (boot or data) |
| [`google_compute_snapshot`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_snapshot) | Point-in-time snapshot for backup and cloning |

---

## Related Docs

- [Google Compute Engine Overview](https://cloud.google.com/compute/docs)
- [Machine Families and Types](https://cloud.google.com/compute/docs/machine-resource)
- [Spot VMs](https://cloud.google.com/compute/docs/instances/spot)
- [Sole-Tenant Nodes](https://cloud.google.com/compute/docs/nodes/sole-tenant-nodes)
- [Shielded VMs](https://cloud.google.com/compute/docs/shielded-vm)
- [Managed Instance Groups](https://cloud.google.com/compute/docs/instance-groups/creating-groups-of-managed-instances)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
