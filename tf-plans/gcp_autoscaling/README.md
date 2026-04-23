# GCP Autoscaling — Terraform Deployment Plan

This deployment plan applies the [GCP Autoscaling Terraform Module](../../modules/networking/gcp_autoscaling/README.md) to provision regional and zonal autoscalers for Managed Instance Groups.

---

## Prerequisites

- Terraform `>= 1.5` installed
- Google provider `>= 6.0`
- Authenticated GCP credentials with `compute.autoscalers.create` / `compute.regionAutoscalers.create` permissions
- Target Managed Instance Groups must exist before running this plan

---

## Quick Start

```bash
cd tf-plans/gcp_autoscaling

# Authenticate
gcloud auth application-default login

# Initialise providers and modules
terraform init

# Review the execution plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

---

## Configuration

Edit `terraform.tfvars` to define your autoscalers. The key fields:

| Field | Description |
|-------|-------------|
| `region` | Set for regional autoscaler (recommended for production) |
| `zone` | Set for zonal autoscaler (GPU, specific hardware) |
| `target` | Self-link of the MIG to autoscale |
| `min_replicas` / `max_replicas` | Scaling bounds |
| `cpu_utilization.target` | 0.0–1.0 CPU fraction |
| `load_balancing_utilization.target` | 0.0–1.0 LB backend fraction |
| `metrics[*].single_instance_assignment` | Queue-depth-per-VM scaling |
| `scaling_schedules` | Cron-based minimum replica overrides |
| `scale_in_control` | Limit scale-in rate to prevent thrashing |

---

## Outputs

| Name | Description |
|------|-------------|
| `autoscaler_ids` | All autoscaler IDs keyed by `key` |
| `autoscaler_names` | All autoscaler names keyed by `key` |
| `autoscaler_self_links` | All autoscaler self-links keyed by `key` |
| `common_labels` | Governance labels for this deployment |

---

## Destroy

```bash
terraform destroy -var-file="terraform.tfvars"
```
