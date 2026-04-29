# ---------------------------------------------------------------------------
# GCP project where all Cloud Run resources are deployed.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID where all Cloud Run services and jobs are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for resources whose location field is left empty.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region used when a service or job location is not set."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels applied to all services and jobs.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date in locals."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Cloud Run v2 Service definitions.
# Each entry creates one google_cloud_run_v2_service resource plus optional
# IAM bindings for public or authenticated invokers.
# ---------------------------------------------------------------------------
variable "services" {
  description = "List of Cloud Run v2 service definitions."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry in tfvars for reference.
    create = optional(bool, true)
    # Cloud Run service resource name (becomes the URL subdomain).
    name = string

    # Location — GCP region for this service. Defaults to var.region when empty.
    location = optional(string, "")

    # ---------------------------------------------------------------------------
    # Container
    # ---------------------------------------------------------------------------
    # Container image URI (e.g. "us-docker.pkg.dev/project/repo/image:tag").
    image = string
    # Override entrypoint command.
    command = optional(list(string), [])
    # Override entrypoint arguments.
    args = optional(list(string), [])
    # HTTP port the container listens on.
    port = optional(number, 8080)

    # ---------------------------------------------------------------------------
    # Resources
    # ---------------------------------------------------------------------------
    # CPU allocation: "1" = 1 vCPU, "2000m" = 2 vCPU, etc.
    cpu = optional(string, "1000m")
    # Memory limit: "512Mi", "1Gi", "2Gi", etc.
    memory = optional(string, "512Mi")
    # When true, CPU is always allocated even between requests (better for background work).
    cpu_always_allocated = optional(bool, false)
    # Boost CPU during container startup to reduce cold-start latency.
    startup_cpu_boost = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Scaling and concurrency
    # ---------------------------------------------------------------------------
    # Max simultaneous requests per container instance (1–1000).
    concurrency = optional(number, 80)
    # Minimum number of instances always warm (0 = scale to zero).
    min_instances = optional(number, 0)
    # Maximum number of instances (controls cost ceiling and DB connections).
    max_instances = optional(number, 100)

    # ---------------------------------------------------------------------------
    # Request handling
    # ---------------------------------------------------------------------------
    # Per-request timeout as ISO 8601 duration (e.g. "300s", "3600s").
    timeout = optional(string, "300s")
    # Execution environment: "EXECUTION_ENVIRONMENT_GEN1" or "EXECUTION_ENVIRONMENT_GEN2" (recommended).
    execution_environment = optional(string, "EXECUTION_ENVIRONMENT_GEN2")

    # ---------------------------------------------------------------------------
    # Networking
    # ---------------------------------------------------------------------------
    # Ingress control: "INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY",
    # or "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER".
    ingress = optional(string, "INGRESS_TRAFFIC_ALL")
    # VPC network for direct VPC egress (leave empty to use public internet only).
    vpc_network = optional(string, "")
    # Subnetwork for direct VPC egress (leave empty to use network default).
    vpc_subnetwork = optional(string, "")
    # Existing Serverless VPC Access connector (alternative to direct VPC egress).
    vpc_connector = optional(string, "")
    # VPC egress mode: "ALL_TRAFFIC" (route everything via VPC) or "PRIVATE_RANGES_ONLY".
    vpc_egress = optional(string, "PRIVATE_RANGES_ONLY")

    # ---------------------------------------------------------------------------
    # Identity
    # ---------------------------------------------------------------------------
    # Service account email the container runs as (Workload Identity recommended).
    service_account_email = optional(string, "")

    # ---------------------------------------------------------------------------
    # IAM
    # ---------------------------------------------------------------------------
    # When true, grants roles/run.invoker to allUsers (public / unauthenticated).
    allow_unauthenticated = optional(bool, false)
    # Specific identities granted roles/run.invoker (e.g. "serviceAccount:sa@proj.iam.gserviceaccount.com").
    invoker_members = optional(list(string), [])

    # ---------------------------------------------------------------------------
    # Environment variables
    # ---------------------------------------------------------------------------
    # Plain key/value env vars (non-sensitive only).
    env_vars = optional(map(string), {})
    # Secret Manager-backed env vars.
    secret_env_vars = optional(list(object({
      env_name = string # Environment variable name inside the container.
      secret   = string # Secret Manager secret resource name.
      version  = optional(string, "latest")
    })), [])

    # ---------------------------------------------------------------------------
    # Secret volumes
    # ---------------------------------------------------------------------------
    # Mount Secret Manager secrets as files inside the container.
    secret_volumes = optional(list(object({
      volume_name = string # Volume name (referenced in volume_mounts).
      mount_path  = string # Filesystem path inside the container.
      secret      = string # Secret Manager secret resource name.
      items = optional(list(object({
        version = optional(string, "latest")
        path    = string # File name within the mount path.
      })), [])
    })), [])

    # ---------------------------------------------------------------------------
    # Traffic splitting
    # ---------------------------------------------------------------------------
    # Traffic blocks to route requests — omit for 100% to LATEST.
    traffic = optional(list(object({
      # "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST" or "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION".
      type     = optional(string, "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST")
      revision = optional(string, "") # Specific revision name (when type = REVISION).
      tag      = optional(string, "") # URL tag for direct revision access.
      percent  = optional(number, 100)
    })), [])

    # ---------------------------------------------------------------------------
    # Revision
    # ---------------------------------------------------------------------------
    # Suffix appended to the service name to form a stable revision name.
    # Leave empty for auto-generated names.
    revision_suffix = optional(string, "")
  }))

  default = []

  validation {
    condition     = length([for s in var.services : s.key]) == length(toset([for s in var.services : s.key]))
    error_message = "Each service entry must have a unique key."
  }
}

# ---------------------------------------------------------------------------
# Cloud Run v2 Job definitions.
# Each entry creates one google_cloud_run_v2_job resource.
# Jobs run to completion — use for ETL, batch processing, migrations.
# ---------------------------------------------------------------------------
variable "jobs" {
  description = "List of Cloud Run v2 job definitions."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry in tfvars for reference.
    create = optional(bool, true)
    # Cloud Run job resource name.
    name = string

    # Location — GCP region for this job. Defaults to var.region when empty.
    location = optional(string, "")

    # ---------------------------------------------------------------------------
    # Container
    # ---------------------------------------------------------------------------
    image   = string
    command = optional(list(string), [])
    args    = optional(list(string), [])

    # ---------------------------------------------------------------------------
    # Resources
    # ---------------------------------------------------------------------------
    cpu    = optional(string, "1000m")
    memory = optional(string, "512Mi")

    # ---------------------------------------------------------------------------
    # Task and retry settings
    # ---------------------------------------------------------------------------
    # Number of parallel task instances to run.
    task_count = optional(number, 1)
    # Maximum number of tasks to run concurrently (0 = unlimited).
    parallelism = optional(number, 0)
    # Maximum number of retries before marking a task as failed.
    max_retries = optional(number, 3)
    # Per-task wall-clock timeout as ISO 8601 duration.
    timeout = optional(string, "3600s")

    # ---------------------------------------------------------------------------
    # Identity
    # ---------------------------------------------------------------------------
    service_account_email = optional(string, "")

    # ---------------------------------------------------------------------------
    # Environment variables
    # ---------------------------------------------------------------------------
    env_vars = optional(map(string), {})
    secret_env_vars = optional(list(object({
      env_name = string
      secret   = string
      version  = optional(string, "latest")
    })), [])

    # ---------------------------------------------------------------------------
    # Networking
    # ---------------------------------------------------------------------------
    vpc_network    = optional(string, "")
    vpc_subnetwork = optional(string, "")
    vpc_connector  = optional(string, "")
    vpc_egress     = optional(string, "PRIVATE_RANGES_ONLY")
  }))

  default = []

  validation {
    condition     = length([for j in var.jobs : j.key]) == length(toset([for j in var.jobs : j.key]))
    error_message = "Each job entry must have a unique key."
  }
}
