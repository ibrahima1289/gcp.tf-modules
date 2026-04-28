# GCP GKE — Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs) that creates one or many clusters — Standard or Autopilot — with fully configurable node pools, networking, security, and observability settings. All entries are optional via `create = optional(bool, true)`.

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                         GKE Cluster (per entry)                         │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                Control Plane (managed by Google)                  │  │
│  │   API Server · etcd · Scheduler · Controller Manager              │  │
│  │   Release channel: RAPID / REGULAR / STABLE                       │  │
│  └───────────────────────┬───────────────────────────────────────────┘  │
│                          │ kubeconfig / kubectl                         │
│  ┌───────────────────────▼───────────────────────────────────────────┐  │
│  │                   Node Pools (Standard mode)                      │  │
│  │                                                                   │  │
│  │  Pool A (general)    Pool B (high-mem)    Pool C (Spot / batch)   │  │
│  │  e2-standard-4       n2-highmem-8         e2-medium (spot=true)   │  │
│  │  autoscaling 1-10    autoscaling 1-5       autoscaling 0-20       │  │
│  └───────────────────────┬───────────────────────────────────────────┘  │
│                          │                                              │
│  ┌───────────────────────▼───────────────────────────────────────────┐  │
│  │                VPC-native Networking (alias IP)                   │  │
│  │  VPC network · Subnetwork · Pod CIDR · Service CIDR               │  │
│  │  Private nodes · Private endpoint (optional)                      │  │
│  │  Master authorized networks (optional CIDR allowlist)             │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘

  Step 1: google_container_cluster.standard   (remove_default_node_pool = true)
  Step 2: google_container_cluster.autopilot  (enable_autopilot = true)
  Step 3: google_container_node_pool.pools    (keyed "<cluster_key>/<pool_key>")

  Autopilot clusters skip Step 3 — Google manages all nodes automatically.
```

---

## Resources Created

| Step | Resource | Purpose |
|------|----------|---------|
| 1 | [`google_container_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) (standard) | Standard cluster with default pool removed immediately |
| 2 | [`google_container_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) (autopilot) | Autopilot cluster — Google manages all node lifecycle |
| 3 | [`google_container_node_pool`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | Separately managed node pools for standard clusters |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |

### IAM required

| Role | Scope |
|------|-------|
| `roles/container.admin` | Project |
| `roles/compute.networkAdmin` | Project (for VPC-native networking) |
| `roles/iam.serviceAccountUser` | Project (to attach node service accounts) |

---

## Usage

### Example 1 — Standard regional cluster with two node pools

```hcl
module "gcp_gke" {
  source     = "../../modules/compute/gcp_gke"
  project_id = "my-project"
  region     = "us-central1"

  clusters = [
    {
      key      = "prod-web"
      create   = true
      name     = "prod-web-cluster"
      location = "us-central1"   # regional = 3-zone HA

      network                   = "projects/my-project/global/networks/prod-vpc"
      subnetwork                = "projects/my-project/regions/us-central1/subnetworks/prod-gke"
      cluster_secondary_range_name  = "pods"
      services_secondary_range_name = "services"

      enable_private_nodes       = true
      master_ipv4_cidr_block     = "172.16.0.0/28"
      master_authorized_networks = [{ cidr_block = "10.0.0.0/8", display_name = "corp-vpn" }]

      release_channel        = "REGULAR"
      workload_identity_pool = "my-project.svc.id.goog"
      enable_managed_prometheus = true
      maintenance_start_time    = "03:00"

      node_pools = [
        {
          key            = "general"
          name           = "general-pool"
          machine_type   = "e2-standard-4"
          autoscaling    = true
          min_node_count = 2
          max_node_count = 10
          disk_size_gb   = 100
          disk_type      = "pd-balanced"
          labels         = { workload = "general" }
        },
        {
          key            = "spot-batch"
          name           = "spot-batch-pool"
          machine_type   = "e2-standard-2"
          spot           = true
          autoscaling    = true
          min_node_count = 0
          max_node_count = 20
          taints = [{
            key    = "cloud.google.com/gke-spot"
            value  = "true"
            effect = "NO_SCHEDULE"
          }]
        }
      ]
    }
  ]

  tags = { env = "prod", team = "platform" }
}
```

### Example 2 — Autopilot cluster

```hcl
module "gcp_gke" {
  source     = "../../modules/compute/gcp_gke"
  project_id = "my-project"
  region     = "us-central1"

  clusters = [
    {
      key       = "dev-autopilot"
      create    = true
      name      = "dev-autopilot-cluster"
      autopilot = true
      location  = "us-central1"

      network    = "default"
      subnetwork = "default"

      release_channel        = "REGULAR"
      workload_identity_pool = "my-project.svc.id.goog"
      # node_pools is ignored for autopilot clusters
    }
  ]

  tags = { env = "dev", team = "platform" }
}
```

---

## Variables

### Common

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `project_id` | `string` | — | ✅ | GCP project ID |
| `region` | `string` | `us-central1` | ❌ | Default cluster location |
| `tags` | `map(string)` | `{}` | ❌ | Governance labels |

---

### `clusters[]` — top-level cluster fields

| Field | Type | Default | Required | Description |
|-------|------|---------|:--------:|-------------|
| `key` | `string` | — | ✅ | Unique stable map key |
| `create` | `bool` | `true` | ❌ | Set `false` to skip creation |
| `name` | `string` | — | ✅ | GKE cluster resource name |
| `location` | `string` | `""` | ❌ | Region (HA) or zone. Defaults to `var.region` |
| `autopilot` | `bool` | `false` | ❌ | Enable Autopilot mode (ignores `node_pools`) |
| `network` | `string` | `default` | ❌ | VPC network name or self-link |
| `subnetwork` | `string` | `default` | ❌ | Subnetwork name or self-link |
| `cluster_secondary_range_name` | `string` | `""` | ❌ | Existing secondary range for Pods |
| `services_secondary_range_name` | `string` | `""` | ❌ | Existing secondary range for Services |
| `pods_ipv4_cidr_block` | `string` | `""` | ❌ | Auto-allocated pod CIDR (used if range name is empty) |
| `services_ipv4_cidr_block` | `string` | `""` | ❌ | Auto-allocated service CIDR |
| `enable_private_nodes` | `bool` | `false` | ❌ | Nodes get only private IPs |
| `enable_private_endpoint` | `bool` | `false` | ❌ | Master API server also private |
| `master_ipv4_cidr_block` | `string` | `172.16.0.0/28` | ❌ | /28 CIDR for master node VMs |
| `master_authorized_networks` | `list({cidr_block, display_name})` | `[]` | ❌ | CIDRs allowed to reach the API server |
| `release_channel` | `string` | `REGULAR` | ❌ | `RAPID`, `REGULAR`, `STABLE`, or `UNSPECIFIED` |
| `min_master_version` | `string` | `""` | ❌ | Explicit K8s version (only with `UNSPECIFIED`) |
| `workload_identity_pool` | `string` | `""` | ❌ | `<project>.svc.id.goog` to enable Workload Identity |
| `enable_binary_authorization` | `bool` | `false` | ❌ | Enforce image signing at admission |
| `logging_service` | `string` | `logging.googleapis.com/kubernetes` | ❌ | GKE logging endpoint |
| `monitoring_service` | `string` | `monitoring.googleapis.com/kubernetes` | ❌ | GKE monitoring endpoint |
| `enable_managed_prometheus` | `bool` | `false` | ❌ | Enable GKE Managed Collection |
| `enable_network_policy` | `bool` | `false` | ❌ | Enable Calico network policy |
| `enable_http_load_balancing` | `bool` | `true` | ❌ | HTTP LB add-on (required for Ingress) |
| `enable_hpa` | `bool` | `true` | ❌ | Horizontal Pod Autoscaler add-on |
| `maintenance_start_time` | `string` | `""` | ❌ | UTC daily maintenance window start (e.g. `03:00`) |
| `deletion_protection` | `bool` | `false` | ❌ | Set `true` to block `terraform destroy` in production |

---

### `clusters[].node_pools[]` — node pool fields (standard mode only)

| Field | Type | Default | Required | Description |
|-------|------|---------|:--------:|-------------|
| `key` | `string` | — | ✅ | Unique key within this cluster |
| `name` | `string` | — | ✅ | Node pool resource name |
| `node_count` | `number` | `1` | ❌ | Fixed node count (when `autoscaling = false`) |
| `autoscaling` | `bool` | `true` | ❌ | Enable cluster autoscaler |
| `min_node_count` | `number` | `1` | ❌ | Minimum nodes per zone |
| `max_node_count` | `number` | `3` | ❌ | Maximum nodes per zone |
| `machine_type` | `string` | `e2-medium` | ❌ | GCE machine type |
| `disk_size_gb` | `number` | `100` | ❌ | Boot disk size |
| `disk_type` | `string` | `pd-standard` | ❌ | `pd-standard`, `pd-ssd`, `pd-balanced` |
| `image_type` | `string` | `COS_CONTAINERD` | ❌ | Node OS image (`COS_CONTAINERD` recommended) |
| `spot` | `bool` | `false` | ❌ | Use Spot VMs for lower cost |
| `service_account` | `string` | `default` | ❌ | Node VM service account |
| `oauth_scopes` | `list(string)` | `[cloud-platform]` | ❌ | OAuth scopes for the node SA |
| `labels` | `map(string)` | `{}` | ❌ | Kubernetes node labels |
| `tags` | `list(string)` | `[]` | ❌ | GCE network tags for firewall rules |
| `taints[].key` | `string` | — | ✅ | Taint key |
| `taints[].value` | `string` | — | ✅ | Taint value |
| `taints[].effect` | `string` | — | ✅ | `NO_SCHEDULE`, `PREFER_NO_SCHEDULE`, `NO_EXECUTE` |
| `auto_repair` | `bool` | `true` | ❌ | Auto-repair unhealthy nodes |
| `auto_upgrade` | `bool` | `true` | ❌ | Auto-upgrade nodes to latest minor version |
| `max_surge` | `number` | `1` | ❌ | Extra nodes during rolling upgrade |
| `max_unavailable` | `number` | `0` | ❌ | Max nodes unavailable during upgrade |

---

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_names` | Cluster resource names, keyed by `cluster.key` |
| `cluster_ids` | Cluster resource IDs, keyed by `cluster.key` |
| `cluster_endpoints` | HTTPS Kubernetes API endpoints *(sensitive)*, keyed by `cluster.key` |
| `cluster_ca_certificates` | Base64 cluster CA certs *(sensitive)*, keyed by `cluster.key` |
| `cluster_locations` | Effective cluster locations, keyed by `cluster.key` |
| `node_pool_ids` | Node pool IDs, keyed by `<cluster_key>/<pool_key>` |
| `node_pool_instance_group_urls` | Instance group self-links per node pool |
| `common_labels` | Merged governance labels |

---

## Notes

- **Regional vs zonal**: Set `location` to a region (e.g. `us-central1`) for a 3-zone HA cluster, or a zone (e.g. `us-central1-a`) for a single-zone cluster.
- **Node pool state keys**: Node pools use `<cluster_key>/<pool_key>` keys so reordering entries in `terraform.tfvars` never destroys and recreates resources.
- **Workload Identity**: Set `workload_identity_pool = "<project>.svc.id.goog"` and annotate the Kubernetes ServiceAccount with the GCP SA email.
- **Spot VMs**: Set `spot = true` and add a `NoSchedule` taint so only tolerating workloads land on Spot nodes.
- **Private clusters**: Require a Cloud NAT or Proxy VM for outbound internet access from nodes.
- **Deletion protection**: Set `deletion_protection = true` in production to prevent accidental `terraform destroy`.
