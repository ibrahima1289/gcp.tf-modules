# GCP Cloud Run — Terraform Module

Terraform module for deploying [Google Cloud Run v2](https://cloud.google.com/run/docs) **Services** (HTTP request handlers) and **Jobs** (finite batch tasks) with full configuration support, IAM bindings, Secret Manager integration, and direct VPC egress.

> Back to [GCP Module Service List](../../../gcp-module-service-list.md)

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│  var.services (list)                  var.jobs (list)                   │
│                                                                         │
│  ┌─────────────────────────────┐   ┌──────────────────────────────┐    │
│  │  google_cloud_run_v2_service│   │  google_cloud_run_v2_job     │    │
│  │  ─────────────────────────  │   │  ──────────────────────────  │    │
│  │  • Revision / traffic split │   │  • task_count / parallelism  │    │
│  │  • Scaling (min/max)        │   │  • max_retries / timeout     │    │
│  │  • CPU always-allocated     │   │  • Secret env vars           │    │
│  │  • Direct VPC egress        │   │  • Direct VPC egress         │    │
│  │  • Secret env vars/volumes  │   └──────────────────────────────┘    │
│  └────────────┬────────────────┘                                        │
│               │                                                         │
│   ┌───────────▼────────────────┐                                        │
│   │  IAM (Step 3 + 4)          │                                        │
│   │  allUsers → public service │                                        │
│   │  invoker_members → private │                                        │
│   └────────────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────────────┘

Traffic flow (Service):

Internet / Internal LB
        │
        ▼ HTTPS (auto TLS)
Cloud Run Service endpoint
        │
   Traffic split
   ├── Revision N   (e.g. 90%)  ◄── current deploy
   └── Revision N-1 (e.g. 10%) ◄── canary / rollback
        │
   Container (Gen2 sandbox)
        │
   ├── Artifact Registry (image pull)
   ├── Secret Manager   (secrets)
   └── VPC (optional direct egress → Cloud SQL, Redis, etc.)
```

---

## Resources Created

| Step | Resource | Description |
|------|----------|-------------|
| 1 | `google_cloud_run_v2_service` | HTTP service with auto-scaling, traffic splitting, VPC egress |
| 2 | `google_cloud_run_v2_job` | Batch job with task parallelism and retry |
| 3 | `google_cloud_run_v2_service_iam_member` (public) | Grants `allUsers` invoker when `allow_unauthenticated = true` |
| 4 | `google_cloud_run_v2_service_iam_member` (private) | Grants `invoker_members` identities invoker access |

---

## Requirements

| Requirement | Version |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | Cloud Run API (`run.googleapis.com`), Artifact Registry API |
| IAM (deployer) | `roles/run.admin`, `roles/iam.serviceAccountUser` |

---

## Usage Examples

### Example 1 — Public API Service

```hcl
module "cloud_run" {
  source     = "../../modules/compute/gcp_cloud_run"
  project_id = "my-gcp-project"
  region     = "us-central1"

  tags = { env = "prod", team = "platform" }

  services = [
    {
      key   = "api"
      name  = "my-api"
      image = "us-docker.pkg.dev/my-gcp-project/backend/api:v1.2.0"

      cpu    = "1000m"
      memory = "512Mi"

      min_instances = 1
      max_instances = 50
      concurrency   = 80

      allow_unauthenticated = true

      env_vars = {
        APP_ENV  = "production"
        LOG_LEVEL = "info"
      }

      secret_env_vars = [
        {
          env_name = "DB_PASSWORD"
          secret   = "projects/my-gcp-project/secrets/db-password"
          version  = "latest"
        }
      ]
    }
  ]
}
```

### Example 2 — Private Service with VPC Egress + Traffic Splitting

```hcl
module "cloud_run" {
  source     = "../../modules/compute/gcp_cloud_run"
  project_id = "my-gcp-project"
  region     = "us-central1"

  services = [
    {
      key   = "backend"
      name  = "internal-backend"
      image = "us-docker.pkg.dev/my-gcp-project/backend/svc:v2.0.0"

      ingress               = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
      cpu_always_allocated  = true
      min_instances         = 2
      max_instances         = 20

      service_account_email = "cloud-run-sa@my-gcp-project.iam.gserviceaccount.com"

      invoker_members = [
        "serviceAccount:frontend-sa@my-gcp-project.iam.gserviceaccount.com"
      ]

      vpc_network    = "projects/my-gcp-project/global/networks/prod-vpc"
      vpc_subnetwork = "projects/my-gcp-project/regions/us-central1/subnetworks/run-subnet"
      vpc_egress     = "ALL_TRAFFIC"

      traffic = [
        { type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST",   percent = 90 },
        { type = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION", revision = "internal-backend-v1", percent = 10 }
      ]
    }
  ]
}
```

### Example 3 — Batch Job

```hcl
module "cloud_run" {
  source     = "../../modules/compute/gcp_cloud_run"
  project_id = "my-gcp-project"
  region     = "us-central1"

  jobs = [
    {
      key        = "etl"
      name       = "daily-etl"
      image      = "us-docker.pkg.dev/my-gcp-project/etl/pipeline:latest"
      task_count  = 10
      parallelism = 5
      max_retries = 2
      timeout     = "3600s"
      cpu         = "2000m"
      memory      = "2Gi"

      env_vars = { GCS_BUCKET = "my-etl-bucket" }

      secret_env_vars = [
        { env_name = "BQ_KEY", secret = "bq-service-account-key", version = "latest" }
      ]
    }
  ]
}
```

---

## Variables — Services (`var.services[]`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable Terraform map key |
| `create` | `bool` | `true` | Set `false` to skip |
| `name` | `string` | required | Cloud Run service name |
| `location` | `string` | `var.region` | GCP region |
| `image` | `string` | required | Container image URI |
| `command` | `list(string)` | `[]` | Override container entrypoint |
| `args` | `list(string)` | `[]` | Override container arguments |
| `port` | `number` | `8080` | HTTP port the container listens on |
| `cpu` | `string` | `"1000m"` | vCPU limit |
| `memory` | `string` | `"512Mi"` | Memory limit |
| `cpu_always_allocated` | `bool` | `false` | CPU allocated even between requests |
| `startup_cpu_boost` | `bool` | `false` | Extra CPU during cold start |
| `concurrency` | `number` | `80` | Max simultaneous requests per instance |
| `min_instances` | `number` | `0` | Min warm instances (0 = scale to zero) |
| `max_instances` | `number` | `100` | Max instances |
| `timeout` | `string` | `"300s"` | Per-request timeout (ISO 8601) |
| `execution_environment` | `string` | `"EXECUTION_ENVIRONMENT_GEN2"` | Gen1 or Gen2 sandbox |
| `ingress` | `string` | `"INGRESS_TRAFFIC_ALL"` | Traffic source restriction |
| `vpc_network` | `string` | `""` | VPC network for direct egress |
| `vpc_subnetwork` | `string` | `""` | Subnetwork for direct egress |
| `vpc_connector` | `string` | `""` | Serverless VPC connector (alternative to direct egress) |
| `vpc_egress` | `string` | `"PRIVATE_RANGES_ONLY"` | `ALL_TRAFFIC` or `PRIVATE_RANGES_ONLY` |
| `service_account_email` | `string` | `""` | Service account email (Workload Identity) |
| `allow_unauthenticated` | `bool` | `false` | Grant `allUsers` invoker |
| `invoker_members` | `list(string)` | `[]` | Identities granted `roles/run.invoker` |
| `env_vars` | `map(string)` | `{}` | Plain environment variables |
| `secret_env_vars` | `list(object)` | `[]` | Secret Manager-backed env vars |
| `secret_volumes` | `list(object)` | `[]` | Secrets mounted as files |
| `traffic` | `list(object)` | `[]` | Traffic splitting rules |
| `revision_suffix` | `string` | `""` | Stable revision name suffix |

---

## Variables — Jobs (`var.jobs[]`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `string` | required | Unique stable Terraform map key |
| `create` | `bool` | `true` | Set `false` to skip |
| `name` | `string` | required | Cloud Run job name |
| `location` | `string` | `var.region` | GCP region |
| `image` | `string` | required | Container image URI |
| `command` | `list(string)` | `[]` | Override container entrypoint |
| `args` | `list(string)` | `[]` | Override container arguments |
| `cpu` | `string` | `"1000m"` | vCPU limit per task |
| `memory` | `string` | `"512Mi"` | Memory limit per task |
| `task_count` | `number` | `1` | Number of parallel task instances |
| `parallelism` | `number` | `0` | Max concurrent tasks (0 = unlimited) |
| `max_retries` | `number` | `3` | Retries before marking task failed |
| `timeout` | `string` | `"3600s"` | Per-task wall-clock timeout |
| `service_account_email` | `string` | `""` | Service account for task identity |
| `env_vars` | `map(string)` | `{}` | Plain environment variables |
| `secret_env_vars` | `list(object)` | `[]` | Secret Manager-backed env vars |
| `vpc_network` | `string` | `""` | VPC network for direct egress |
| `vpc_subnetwork` | `string` | `""` | Subnetwork for direct egress |
| `vpc_connector` | `string` | `""` | Serverless VPC connector |
| `vpc_egress` | `string` | `"PRIVATE_RANGES_ONLY"` | Egress mode |

---

## Outputs

| Output | Description |
|--------|-------------|
| `service_urls` | HTTPS endpoints, keyed by service key |
| `service_names` | Service resource names |
| `service_ids` | Fully-qualified service IDs |
| `service_latest_revisions` | Latest ready revision names |
| `service_locations` | Service deployment regions |
| `job_names` | Job resource names, keyed by job key |
| `job_ids` | Fully-qualified job IDs |
| `job_locations` | Job deployment regions |
| `common_labels` | Merged governance labels |

---

## Notes

- **Scale to zero**: `min_instances = 0` (default) eliminates idle costs; set `min_instances >= 1` to eliminate cold starts.
- **Gen2 execution environment**: Use `EXECUTION_ENVIRONMENT_GEN2` for all new services — faster cold starts, full Linux process model, better network throughput.
- **Direct VPC egress vs. connector**: Set `vpc_network` to use direct VPC egress (no connector needed for `google` provider `>= 5.x`). Use `vpc_connector` for compatibility with older deployments.
- **CPU always-allocated**: Required for background threads (e.g. gRPC keepalive, Pub/Sub push consumers). Set `cpu_always_allocated = true` and `min_instances >= 1`.
- **Traffic splitting**: Canary and blue-green deployments are controlled via `traffic` blocks. When `traffic = []`, 100% routes to the latest revision automatically.
- **Jobs vs. Scheduler**: Jobs are infrastructure declarations only — use [Cloud Scheduler](https://cloud.google.com/scheduler) to trigger them on a schedule via the Cloud Run Jobs API.
