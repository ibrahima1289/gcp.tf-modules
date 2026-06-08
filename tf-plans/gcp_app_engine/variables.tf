# variables.tf

# ---------------------------------------------------------------------------
# Default project for the App Engine application.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID for the App Engine application and all service versions."
  type        = string
}

# ---------------------------------------------------------------------------
# Region kept for interface consistency; location is set via application.location_id.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Interface consistency variable. App Engine location is permanent and configured via application.location_id."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with generated metadata into all versioned resource labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# App Engine application (singleton per project).
# ---------------------------------------------------------------------------
variable "application" {
  description = "App Engine application configuration. location_id is permanent after the first apply."
  type = object({
    location_id    = string
    create         = optional(bool, true)
    serving_status = optional(string, "SERVING")
    database_type  = optional(string, "CLOUD_FIRESTORE")
    auth_domain    = optional(string, "")

    iap_enabled              = optional(bool, false)
    iap_oauth2_client_id     = optional(string, "")
    iap_oauth2_client_secret = optional(string, "")

    feature_settings_split_health_checks = optional(bool, true)
  })

  default = {
    location_id = "us-central"
  }
}

# ---------------------------------------------------------------------------
# One or many App Engine service versions.
# ---------------------------------------------------------------------------
variable "services" {
  description = "List of App Engine service version configurations (standard or flexible)."
  type = list(object({
    key        = string
    service    = string
    runtime    = string
    env_type   = optional(string, "standard")
    version_id = optional(string, "v1")
    create     = optional(bool, true)
    project_id = optional(string, "")

    deployment_type            = optional(string, "zip")
    deployment_zip_source_url  = optional(string, "")
    deployment_zip_files_count = optional(number, 0)
    deployment_container_image = optional(string, "")

    deployment_files = optional(list(object({
      name       = string
      source_url = string
      sha1_sum   = optional(string, "")
    })), [])

    entrypoint_shell    = optional(string, "")
    env_variables       = optional(map(string), {})
    labels              = optional(map(string), {})
    inbound_services    = optional(list(string), [])
    runtime_api_version = optional(string, "")

    instance_class = optional(string, "F1")
    threadsafe     = optional(bool, true)
    serving_status = optional(string, "SERVING")

    scaling_type = optional(string, "automatic")

    max_concurrent_requests       = optional(number, 10)
    max_idle_instances            = optional(number, 1)
    max_pending_latency           = optional(string, "automatic")
    min_idle_instances            = optional(number, 0)
    min_pending_latency           = optional(string, "30ms")
    target_cpu_utilization        = optional(number, 0.6)
    target_throughput_utilization = optional(number, 0.6)
    min_instances                 = optional(number, 0)
    max_instances                 = optional(number, 10)

    flex_cool_down_period          = optional(string, "120s")
    flex_aggregation_window_length = optional(string, "60s")

    basic_scaling_idle_timeout  = optional(string, "5m")
    basic_scaling_max_instances = optional(number, 5)

    manual_scaling_instances = optional(number, 1)

    resources_cpu       = optional(number, 1)
    resources_disk_gb   = optional(number, 10)
    resources_memory_gb = optional(number, 0.6)

    liveness_check_path              = optional(string, "/")
    liveness_check_initial_delay     = optional(string, "300s")
    liveness_check_check_interval    = optional(string, "30s")
    liveness_check_timeout           = optional(string, "4s")
    liveness_check_failure_threshold = optional(number, 4)
    liveness_check_success_threshold = optional(number, 2)

    readiness_check_path              = optional(string, "/")
    readiness_check_check_interval    = optional(string, "5s")
    readiness_check_timeout           = optional(string, "4s")
    readiness_check_failure_threshold = optional(number, 2)
    readiness_check_success_threshold = optional(number, 2)
    readiness_check_app_start_timeout = optional(string, "300s")

    traffic_split_enabled  = optional(bool, false)
    traffic_split_shard_by = optional(string, "RANDOM")
    traffic_allocations    = optional(map(string), {})

    noop_on_destroy           = optional(bool, true)
    delete_service_on_destroy = optional(bool, false)
  }))

  default = []

  validation {
    condition     = length(distinct([for s in var.services : s.key])) == length(var.services)
    error_message = "services[*].key values must be unique."
  }
}

# ---------------------------------------------------------------------------
# App Engine firewall rules.
# ---------------------------------------------------------------------------
variable "firewall_rules" {
  description = "List of App Engine firewall rules. Evaluated in ascending priority order (lower number = higher precedence)."
  type = list(object({
    key          = string
    priority     = number
    action       = string
    source_range = string
    description  = optional(string, "")
    create       = optional(bool, true)
  }))

  default = []
}

# ---------------------------------------------------------------------------
# Custom domain mappings.
# ---------------------------------------------------------------------------
variable "domain_mappings" {
  description = "List of custom domain mappings. After apply, add dns_records output to your DNS provider."
  type = list(object({
    key                 = string
    domain_name         = string
    override_strategy   = optional(string, "STRICT")
    ssl_management_type = optional(string, "AUTOMATIC")
    ssl_certificate_id  = optional(string, "")
    create              = optional(bool, true)
  }))

  default = []
}

# ---------------------------------------------------------------------------
# URL dispatch rules.
# ---------------------------------------------------------------------------
variable "dispatch_rules" {
  description = "URL dispatch rules routing requests to specific services by domain/path patterns."
  type = list(object({
    domain  = string
    path    = string
    service = string
  }))

  default = []
}
