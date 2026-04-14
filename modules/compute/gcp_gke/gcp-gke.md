# Google Kubernetes Engine (GKE)

## Service overview

[Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs) is Google Cloud's fully managed Kubernetes platform. Google operates the control plane (API server, etcd, schedulers, controllers) on your behalf, and you manage the workloads running on node pools. GKE integrates deeply with Cloud IAM, VPC networking, Cloud Logging, Cloud Monitoring, Artifact Registry, and Binary Authorization.

---

## How GKE works

A GKE cluster consists of:

- **Control plane** — managed by Google; hosts the Kubernetes API server and system components
- **Node pools** — groups of worker VMs (Compute Engine instances) where workloads run
- **Pods / workloads** — the containers you deploy to the cluster
- **Services / Ingress** — expose workloads inside or outside the cluster
- **Cluster add-ons** — optional components like Managed Prometheus, Config Sync, or Anthos Service Mesh

```text
Users / Clients
      |
Ingress / Load Balancer (Google Cloud L4 / L7)
      |
GKE Cluster (control plane managed by Google)
  ├── Node Pool A (general workloads — e2-standard-4)
  ├── Node Pool B (high-memory — m2-highmem-16)
  ├── Node Pool C (Spot VMs — batch/fault-tolerant jobs)
  └── System workloads (kube-dns, metrics-server, etc.)
      |
Managed services (Cloud SQL, Cloud Storage, Pub/Sub, etc.)
```

---

## Cluster modes

| Mode | Description | When to use |
|------|-------------|-------------|
| **Standard** | You manage node pools, OS, and node scaling | Production: you need full control over node configuration |
| **Autopilot** | Google manages nodes, scaling, and bin-packing | Teams that want zero node ops; pay per Pod resource request |

> **Autopilot** is the recommended mode for new clusters unless you need custom node configurations, DaemonSets, or GPUs.

---

## GKE tiers

| Tier | SLA | Features | Use case |
|------|-----|----------|----------|
| **Standard** | 99.5% (zonal) / 99.95% (regional) | Core Kubernetes, community support | General workloads |
| **Enterprise** | 99.95% | Compliance controls, multi-cluster fleet, Anthos integration | Regulated / large enterprise |

---

## Node pool configurations

| Node pool type | Machine family | Typical use |
|----------------|---------------|-------------|
| General purpose | E2, N2 | Web services, APIs, most microservices |
| High-memory | M1, M2 | In-memory caches, JVM-heavy workloads |
| Compute-optimized | C2, C3 | CPU-bound batch jobs, high-frequency compute |
| GPU-attached | A2, A3, G2 | ML inference/training, rendering |
| Spot VMs | Any family | Fault-tolerant batch, CI/CD runners |
| ARM | T2A | Cost-efficient containerized scale-out |

---

## Release channels

| Channel | Update cadence | Best for |
|---------|---------------|----------|
| **Rapid** | Weeks after upstream | Evaluating new features |
| **Regular** | Months after upstream | Most production clusters |
| **Stable** | Quarters after upstream | Regulated/conservative environments |
| **Extended** | Longer support window | Long-cycle enterprise stability requirements |

---

## Autoscaling options

| Mechanism | What it scales | Trigger |
|-----------|---------------|---------|
| **Horizontal Pod Autoscaler (HPA)** | Pod replicas | CPU / memory / custom metrics |
| **Vertical Pod Autoscaler (VPA)** | Pod CPU/memory requests | Actual usage over time |
| **Cluster Autoscaler** | Node count in a pool | Pending pods / low utilization |
| **Node Auto-Provisioning (NAP)** | New node pools | Unschedulable pods with no matching pool |
| **Multidimensional Autoscaler** | Pod replicas (combination) | HPA + CPU + custom together |

---

## When to use GKE

- You run many microservices requiring container orchestration and lifecycle management.
- You need autoscaling, rolling updates, and self-healing workloads.
- You want centralized policy and workload isolation for multiple teams.
- You need GPU-attached nodes for ML training or inference.
- You are building an internal developer platform with a shared compute foundation.

---

## Core capabilities

- Managed control plane with optional regional high availability.
- Node pools with autoscaling and workload-specific machine profiles.
- Horizontal, vertical, and cluster autoscaling.
- Native integrations with IAM, VPC, Cloud Logging, and Cloud Monitoring.
- Private clusters, Workload Identity, and binary authorization policy controls.
- Fleet management for multi-cluster governance across environments.

---

## Real-world usage

- Multi-team internal developer platform with namespace-level isolation.
- API and event-driven microservice ecosystems with mixed scaling profiles.
- Stateful workloads (Kafka, Cassandra, PostgreSQL via StatefulSets).
- ML model training on GPU node pools using Kubeflow or Ray.
- Hybrid service mesh and progressive deployment (blue/green, canary).

---

## Security and operations guidance

- Use private clusters and restrict control-plane authorized networks.
- Enforce Workload Identity instead of long-lived service account keys on nodes.
- Apply Kubernetes NetworkPolicy and GKE network policy enforcement per namespace.
- Use Binary Authorization to ensure only trusted images are admitted.
- Use regional clusters for production-critical services; zonal only for dev/test.
- Keep system workloads in dedicated node pools with taints to prevent co-scheduling.
- Define resource `requests` and `limits` for all containers; use LimitRange defaults.
- Right-size node pools with NAP; enable cluster autoscaler for cost efficiency.
- Use Spot VM node pools for fault-tolerant batch jobs to cut compute costs.
- Monitor per-namespace cost trends with labels and billing exports.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_container_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | GKE cluster (control plane + initial node pool) |
| [`google_container_node_pool`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | Additional node pools with custom configurations |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `container.googleapis.com` API |
| [`google_service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) | Dedicated node service account (least-privilege) |

---

## Related Docs

- [Google Kubernetes Engine Overview](https://cloud.google.com/kubernetes-engine/docs)
- [GKE Autopilot Overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [GKE Node Pools](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
