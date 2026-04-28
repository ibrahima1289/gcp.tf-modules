# GCP Cloud Run — Terraform Deployment Plan

This plan calls the [`gcp_cloud_run`](../../modules/compute/gcp_cloud_run/README.md) module
and provides `terraform.tfvars` examples for a public API service, an internal backend service
with VPC egress and traffic splitting, a frontend web app, and two batch jobs.

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | Cloud Run API (`run.googleapis.com`), Artifact Registry API |
| IAM | `roles/run.admin`, `roles/iam.serviceAccountUser` |
| Container images | Must exist in Artifact Registry or Container Registry before `terraform apply` |

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Enable required APIs
gcloud services enable run.googleapis.com artifactregistry.googleapis.com \
  --project=my-gcp-project

# 3. Configure variables
cp terraform.tfvars terraform.auto.tfvars
# Edit terraform.auto.tfvars — update project_id and image URIs

# 4. Set create = true for services/jobs you want to deploy

# 5. Initialise and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## File Reference

| File | Purpose |
|------|---------|
| `main.tf` | Module call |
| `variables.tf` | Input variable declarations |
| `locals.tf` | `created_date` helper |
| `outputs.tf` | Pass-through of all module outputs |
| `providers.tf` | Google provider + Terraform version pin |
| `terraform.tfvars` | Examples: public API, internal backend, frontend, ETL job, migration job |

---

## Service vs Job: When to Use Each

| Scenario | Use |
|----------|-----|
| HTTP API, webhook, web application | Service |
| Background worker (Pub/Sub push, gRPC) | Service + `cpu_always_allocated = true` |
| ETL pipeline, data processing | Job |
| Database migration | Job + `max_retries = 0` |
| Scheduled report generation | Job (triggered by Cloud Scheduler) |
| Long-running batch with parallelism | Job + `task_count` / `parallelism` |

---

## Key Variables (Services)

| Variable | Default | Notes |
|----------|---------|-------|
| `services[].min_instances` | `0` | Set `>= 1` to eliminate cold starts |
| `services[].allow_unauthenticated` | `false` | Set `true` for public endpoints |
| `services[].ingress` | `INGRESS_TRAFFIC_ALL` | Restrict to `INTERNAL_LOAD_BALANCER` for private services |
| `services[].cpu_always_allocated` | `false` | Required for background thread workloads |
| `services[].vpc_network` | `""` | Set for private resource access via direct VPC egress |
| `services[].traffic` | `[]` | 100% to latest; set for canary / blue-green deployments |

---

## Outputs

| Output | Description |
|--------|-------------|
| `service_urls` | HTTPS endpoints per service |
| `service_names` | Service resource names |
| `service_ids` | Fully-qualified service IDs |
| `service_latest_revisions` | Latest ready revision names |
| `service_locations` | Deployment regions |
| `job_names` | Job resource names |
| `job_ids` | Fully-qualified job IDs |
| `job_locations` | Job deployment regions |
| `common_labels` | Merged governance labels |

---

## Invoke a Service

```bash
# Get service URL
terraform output -json service_urls

# Invoke with ID token (authenticated service)
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://<service-url>/health
```

## Run a Job Manually

```bash
# Execute the ETL job
gcloud run jobs execute daily-etl --region=us-central1 --project=my-gcp-project

# Watch execution status
gcloud run jobs executions list --job=daily-etl --region=us-central1
```

## Destroy

```bash
terraform destroy
```

---

*Back to [GCP Module Service List](../../gcp-module-service-list.md)*
