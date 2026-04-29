variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with managed_by and created_date."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Mirror the module's services variable exactly so tfvars entries pass through.
# ---------------------------------------------------------------------------
variable "services" {
  description = "List of Cloud Run v2 service definitions."
  type = list(object({
    key    = string
    create = optional(bool, true)
    name   = string

    location              = optional(string, "")
    image                 = string
    command               = optional(list(string), [])
    args                  = optional(list(string), [])
    port                  = optional(number, 8080)
    cpu                   = optional(string, "1000m")
    memory                = optional(string, "512Mi")
    cpu_always_allocated  = optional(bool, false)
    startup_cpu_boost     = optional(bool, false)
    concurrency           = optional(number, 80)
    min_instances         = optional(number, 0)
    max_instances         = optional(number, 100)
    timeout               = optional(string, "300s")
    execution_environment = optional(string, "EXECUTION_ENVIRONMENT_GEN2")
    ingress               = optional(string, "INGRESS_TRAFFIC_ALL")
    vpc_network           = optional(string, "")
    vpc_subnetwork        = optional(string, "")
    vpc_connector         = optional(string, "")
    vpc_egress            = optional(string, "PRIVATE_RANGES_ONLY")
    service_account_email = optional(string, "")
    allow_unauthenticated = optional(bool, false)
    invoker_members       = optional(list(string), [])
    env_vars              = optional(map(string), {})
    secret_env_vars = optional(list(object({
      env_name = string
      secret   = string
      version  = optional(string, "latest")
    })), [])
    secret_volumes = optional(list(object({
      volume_name = string
      mount_path  = string
      secret      = string
      items = optional(list(object({
        version = optional(string, "latest")
        path    = string
      })), [])
    })), [])
    traffic = optional(list(object({
      type     = optional(string, "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST")
      revision = optional(string, "")
      tag      = optional(string, "")
      percent  = optional(number, 100)
    })), [])
    revision_suffix = optional(string, "")
  }))

  default = []
}

# ---------------------------------------------------------------------------
# Mirror the module's jobs variable exactly so tfvars entries pass through.
# ---------------------------------------------------------------------------
variable "jobs" {
  description = "List of Cloud Run v2 job definitions."
  type = list(object({
    key    = string
    create = optional(bool, true)
    name   = string

    location              = optional(string, "")
    image                 = string
    command               = optional(list(string), [])
    args                  = optional(list(string), [])
    cpu                   = optional(string, "1000m")
    memory                = optional(string, "512Mi")
    task_count            = optional(number, 1)
    parallelism           = optional(number, 0)
    max_retries           = optional(number, 3)
    timeout               = optional(string, "3600s")
    service_account_email = optional(string, "")
    env_vars              = optional(map(string), {})
    secret_env_vars = optional(list(object({
      env_name = string
      secret   = string
      version  = optional(string, "latest")
    })), [])
    vpc_network    = optional(string, "")
    vpc_subnetwork = optional(string, "")
    vpc_connector  = optional(string, "")
    vpc_egress     = optional(string, "PRIVATE_RANGES_ONLY")
  }))

  default = []
}
