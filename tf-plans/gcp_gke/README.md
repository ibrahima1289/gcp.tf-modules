# GCP GKE — Terraform Deployment Plan

This plan calls the [`gcp_gke`](../../modules/compute/gcp_gke/README.md) module
and provides `terraform.tfvars` examples for a standard regional cluster, an
Autopilot cluster, and a GPU zonal cluster.

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | Kubernetes Engine API, Compute Engine API |
| IAM | `roles/container.admin`, `roles/compute.networkAdmin` |
| Networking | VPC, subnetwork, and secondary ranges must exist for private clusters |

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Configure the plan
cp terraform.tfvars terraform.auto.tfvars
# Edit terraform.auto.tfvars — update project_id, network, subnetwork

# 3. Initialise and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 4. Configure kubectl
gcloud container clusters get-credentials <cluster-name> \
  --region us-central1 --project <project-id>
```

---

## Cluster Types

| Variable field | Mode | Description |
|----------------|------|-------------|
| `autopilot = false` | Standard | You manage node pools, machine types, and scaling |
| `autopilot = true` | Autopilot | Google manages all node lifecycle; pay per Pod request |

---

## File Reference

| File | Purpose |
|------|---------|
| `main.tf` | Module call |
| `variables.tf` | Input variable declarations |
| `locals.tf` | `created_date` helper |
| `outputs.tf` | Pass-through of all module outputs |
| `providers.tf` | Google provider + Terraform version pin |
| `terraform.tfvars` | Examples: standard HA, Autopilot, GPU zonal |

---

## Key Variables

| Field | Default | Description |
|-------|---------|-------------|
| `clusters[].key` | required | Unique stable map key |
| `clusters[].create` | `true` | Set `false` to skip creation |
| `clusters[].name` | required | GKE cluster name |
| `clusters[].location` | `var.region` | Region (HA) or zone |
| `clusters[].autopilot` | `false` | Enable Autopilot mode |
| `clusters[].enable_private_nodes` | `false` | Nodes on internal IPs only |
| `clusters[].workload_identity_pool` | `""` | `<project>.svc.id.goog` to enable WI |
| `clusters[].release_channel` | `REGULAR` | `RAPID`, `REGULAR`, `STABLE`, `UNSPECIFIED` |
| `clusters[].deletion_protection` | `false` | Prevent `terraform destroy` |
| `clusters[].node_pools[].machine_type` | `e2-medium` | GCE machine type |
| `clusters[].node_pools[].spot` | `false` | Use Spot VMs |
| `clusters[].node_pools[].autoscaling` | `true` | Enable cluster autoscaler |
| `clusters[].node_pools[].min_node_count` | `1` | Min nodes per zone |
| `clusters[].node_pools[].max_node_count` | `3` | Max nodes per zone |

---

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_names` | Cluster names, keyed by `cluster.key` |
| `cluster_ids` | Cluster resource IDs |
| `cluster_endpoints` | API server HTTPS endpoints *(sensitive)* |
| `cluster_ca_certificates` | CA certs for kubeconfig *(sensitive)* |
| `cluster_locations` | Effective cluster locations |
| `node_pool_ids` | Node pool IDs, keyed by `<cluster_key>/<pool_key>` |
| `node_pool_instance_group_urls` | Instance group self-links per pool |
| `common_labels` | Merged governance labels |

---

## Post-Apply: Connect kubectl

```bash
# Regional cluster
gcloud container clusters get-credentials prod-web-cluster \
  --region us-central1 --project my-gcp-project

# Verify
kubectl get nodes
kubectl get namespaces
```

---

## Destroy

```bash
terraform destroy
```

> Node pools are destroyed before clusters. If `deletion_protection = true`,
> set it to `false` first with `terraform apply` before running destroy.

---

*Back to [GCP Module Service List](../../gcp-module-service-list.md)*
