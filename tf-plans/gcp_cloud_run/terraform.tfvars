project_id = "my-gcp-project"
region     = "us-central1"

tags = {
  env     = "dev"
  team    = "platform"
  owner   = "infra-team"
  project = "my-gcp-project"
}

# ===========================================================================
# Cloud Run Services
# ===========================================================================
services = [
  # ── Public REST API — scales to zero, unauthenticated ────────────────────
  # A stateless HTTP API exposed publicly. Scale-to-zero minimises idle cost.
  # Set create = true after pushing the image to Artifact Registry.
  {
    key    = "public-api"
    create = false
    name   = "public-api"
    image  = "us-docker.pkg.dev/my-gcp-project/backend/api:v1.0.0"

    cpu    = "1000m"
    memory = "512Mi"

    min_instances = 0 # scale to zero — cold start acceptable
    max_instances = 50
    concurrency   = 80
    timeout       = "60s"

    allow_unauthenticated = true
    ingress               = "INGRESS_TRAFFIC_ALL"

    env_vars = {
      APP_ENV   = "production"
      LOG_LEVEL = "info"
      PORT      = "8080"
    }

    secret_env_vars = [
      {
        env_name = "DB_PASSWORD"
        secret   = "projects/my-gcp-project/secrets/db-password"
        version  = "latest"
      }
    ]
  },

  # ── Internal backend service — VPC egress, private ingress ───────────────
  # Accessible only via internal load balancer; routes all traffic through VPC
  # so it can reach Cloud SQL, Memorystore, or other private resources.
  {
    key    = "internal-backend"
    create = false
    name   = "internal-backend"
    image  = "us-docker.pkg.dev/my-gcp-project/backend/svc:v2.0.0"

    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    ingress               = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    cpu_always_allocated  = true # background Pub/Sub subscription threads
    startup_cpu_boost     = true

    cpu    = "2000m"
    memory = "1Gi"

    min_instances = 2 # keep warm — low-latency internal calls
    max_instances = 20
    concurrency   = 100
    timeout       = "300s"

    service_account_email = "cloud-run-backend@my-gcp-project.iam.gserviceaccount.com"

    invoker_members = [
      "serviceAccount:frontend-sa@my-gcp-project.iam.gserviceaccount.com"
    ]

    vpc_network    = "projects/my-gcp-project/global/networks/prod-vpc"
    vpc_subnetwork = "projects/my-gcp-project/regions/us-central1/subnetworks/run-subnet"
    vpc_egress     = "ALL_TRAFFIC"

    env_vars = {
      DB_HOST = "10.10.0.5"
      DB_NAME = "appdb"
    }

    secret_env_vars = [
      {
        env_name = "DB_PASSWORD"
        secret   = "projects/my-gcp-project/secrets/backend-db-pass"
        version  = "latest"
      }
    ]

    # Canary deployment — 90% to latest, 10% to previous revision.
    traffic = [
      { type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST", percent = 90 },
      { type = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION", revision = "internal-backend-v1", percent = 10 }
    ]
  },

  # ── Frontend web app — Gen2, public, with startup CPU boost ──────────────
  {
    key    = "frontend"
    create = false
    name   = "frontend-web"
    image  = "us-docker.pkg.dev/my-gcp-project/frontend/web:latest"

    cpu               = "1000m"
    memory            = "256Mi"
    startup_cpu_boost = true

    min_instances         = 1
    max_instances         = 30
    allow_unauthenticated = true

    env_vars = {
      NEXT_PUBLIC_API_URL = "https://api.example.com"
    }

    revision_suffix = "v3"
  }
]

# ===========================================================================
# Cloud Run Jobs
# ===========================================================================
jobs = [
  # ── Daily ETL pipeline — parallel tasks, Secret Manager credentials ───────
  # Triggered on a schedule by Cloud Scheduler via the Cloud Run Jobs API.
  {
    key         = "daily-etl"
    create      = false
    name        = "daily-etl"
    image       = "us-docker.pkg.dev/my-gcp-project/etl/pipeline:latest"
    task_count  = 10 # 10 independent task instances
    parallelism = 5  # at most 5 run at the same time
    max_retries = 3
    timeout     = "3600s" # 1 hour per task
    cpu         = "2000m"
    memory      = "2Gi"

    service_account_email = "etl-job-sa@my-gcp-project.iam.gserviceaccount.com"

    env_vars = {
      GCS_BUCKET  = "my-etl-bucket"
      BQ_DATASET  = "analytics"
      ENVIRONMENT = "production"
    }

    secret_env_vars = [
      {
        env_name = "BQ_SA_KEY"
        secret   = "projects/my-gcp-project/secrets/bq-service-account-key"
        version  = "latest"
      }
    ]

    vpc_network = "projects/my-gcp-project/global/networks/prod-vpc"
    vpc_egress  = "PRIVATE_RANGES_ONLY"
  },

  # ── Database migration job — single task, high memory ─────────────────────
  {
    key         = "db-migrate"
    create      = false
    name        = "db-migrate"
    image       = "us-docker.pkg.dev/my-gcp-project/migrations/runner:latest"
    task_count  = 1
    parallelism = 1
    max_retries = 0 # do NOT retry migrations automatically
    timeout     = "600s"
    cpu         = "1000m"
    memory      = "1Gi"

    args = ["migrate", "--target=latest"]

    service_account_email = "migration-sa@my-gcp-project.iam.gserviceaccount.com"

    secret_env_vars = [
      {
        env_name = "DATABASE_URL"
        secret   = "projects/my-gcp-project/secrets/database-url"
        version  = "latest"
      }
    ]

    vpc_network    = "projects/my-gcp-project/global/networks/prod-vpc"
    vpc_subnetwork = "projects/my-gcp-project/regions/us-central1/subnetworks/run-subnet"
    vpc_egress     = "ALL_TRAFFIC"
  }
]
