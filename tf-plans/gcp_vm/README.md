# GCP VM — Deployment Plan

> Module: [modules/compute/gcp_vm](../../modules/compute/gcp_vm/README.md) · Back to [README](../../README.md)

Deployment plan wrapper for the [GCP VM Terraform module](../../modules/compute/gcp_vm/README.md). Configures one or many Compute Engine VM instances across multiple zones with optional data disks, networking, Spot scheduling, and Shielded VM features.

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Initialise
terraform init

# 3. Review the plan
terraform plan

# 4. Apply
terraform apply
```

---

## Pre-requisites

- GCP project with Compute Engine API enabled (`compute.googleapis.com`)
- Caller must have `roles/compute.instanceAdmin.v1` and `roles/iam.serviceAccountUser`
- VPC network and subnetwork must exist before applying (default VPC is used in the example)

---

## Configuration — `terraform.tfvars`

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `project_id` | `string` | — | ✅ | GCP project ID |
| `region` | `string` | `us-central1` | ❌ | Default region |
| `tags` | `map(string)` | `{}` | ❌ | Governance labels |
| `vms` | `list(object)` | `[]` | ❌ | VM instance definitions — see [module variables](../../modules/compute/gcp_vm/README.md#variables) |

---

## Examples in `terraform.tfvars`

| Entry key | Purpose | Notes |
|-----------|---------|-------|
| `web-01` | Nginx web server with external IP | `create = true` — enabled by default |
| `db-01` | DB server with 500 GB data disk, no external IP | `create = false` — enable when VPC ready |
| `batch-worker-01` | Spot VM batch worker with Shielded VM | `create = false` — enable when batch job ready |

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_ids` | Instance IDs keyed by `vm.key` |
| `instance_names` | Instance names keyed by `vm.key` |
| `instance_self_links` | Self-links keyed by `vm.key` |
| `internal_ips` | Internal IPs keyed by `vm.key` |
| `external_ips` | External IPs keyed by `vm.key` (empty if none) |
| `data_disk_ids` | Data disk IDs keyed by `<vm_key>/<disk_name>` |
| `common_labels` | Merged governance labels |
