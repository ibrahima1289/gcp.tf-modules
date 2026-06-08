# variables.tf

# ---------------------------------------------------------------------------
# Default project for all App Engine resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID for the App Engine application and all service versions."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Region is kept for interface consistency; App Engine location is set via
# application.location_id and is permanent after first deployment.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Interface consistency variable. App Engine location is permanent and set via application.location_id, not this variable."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels applied to versioned resources.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with module-generated metadata (managed_by, created_date). Applied as labels to versioned resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# App Engine application — singleton per GCP project.
# ---------------------------------------------------------------------------
variable "application" {
  description = "App Engine application configuration. Only one application can exist per GCP project. location_id is permanent after creation."
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

  validation {
    condition     = contains(["SERVING", "USER_DISABLED", "SYSTEM_DISABLED"], var.application.serving_status)
    error_message = "application.serving_status must be one of: SERVING, USER_DISABLED, SYSTEM_DISABLED."
  }

  validation {
    condition     = contains(["CLOUD_DATASTORE", "CLOUD_FIRESTORE", "CLOUD_DATASTORE_COMPATIBILITY"], var.application.database_type)
    error_message = "application.database_type must be one of: CLOUD_DATASTORE, CLOUD_FIRESTORE, CLOUD_DATASTORE_COMPATIBILITY."
  }
}

# ---------------------------------------------------------------------------
# Service versions — standard and flexible environments.
# Each entry creates one immutable version of a named service.
# ---------------------------------------------------------------------------
variable "services" {
  description = "List of App Engine service version configurations. Each entry creates one version of a named service in either standard or flexible environment."
  type = list(object({
    # Identity
    key        = string
    service    = string
    runtime    = string
    env_type   = optional(string, "standard") # "standard" or "flexible"
    version_id = optional(string, "v1")
    create     = optional(bool, true)
    project_id = optional(string, "")

    # Deployment source
    deployment_type            = optional(string, "zip") # "zip" | "files" | "container"
    deployment_zip_source_url  = optional(string, "")
    deployment_zip_files_count = optional(number, 0)
    deployment_container_image = optional(string, "") # flexible + deployment_type="container" only

    deployment_files = optional(list(object({
      name       = string
      source_url = string
      sha1_sum   = optional(string, "")
    })), [])

    # Runtime config
    entrypoint_shell    = optional(string, "")
    env_variables       = optional(map(string), {})
    labels              = optional(map(string), {})
    inbound_services    = optional(list(string), [])
    runtime_api_version = optional(string, "")

    # Standard environment instance class (F = auto-scale, B = basic/manual)
    instance_class = optional(string, "F1")
    threadsafe     = optional(bool, true)
    serving_status = optional(string, "SERVING")

    # Scaling — "automatic", "basic" (standard only), or "manual"
    scaling_type = optional(string, "automatic")

    # Automatic scaling — standard
    max_concurrent_requests       = optional(number, 10)
    max_idle_instances            = optional(number, 1)
    max_pending_latency           = optional(string, "automatic")
    min_idle_instances            = optional(number, 0)
    min_pending_latency           = optional(string, "30ms")
    target_cpu_utilization        = optional(number, 0.6)
    target_throughput_utilization = optional(number, 0.6)
    min_instances                 = optional(number, 0)
    max_instances                 = optional(number, 10)

    # Automatic scaling — flexible-specific additions
    flex_cool_down_period          = optional(string, "120s")
    flex_aggregation_window_length = optional(string, "60s")

    # Basic scaling (standard environment only)
    basic_scaling_idle_timeout  = optional(string, "5m")
    basic_scaling_max_instances = optional(number, 5)

    # Manual scaling
    manual_scaling_instances = optional(number, 1)

    # Flexible environment — compute resources
    resources_cpu       = optional(number, 1)
    resources_disk_gb   = optional(number, 10)
    resources_memory_gb = optional(number, 0.6)

    # Flexible environment — liveness check (required by provider)
    liveness_check_path              = optional(string, "/")
    liveness_check_initial_delay     = optional(string, "300s")
    liveness_check_check_interval    = optional(string, "30s")
    liveness_check_timeout           = optional(string, "4s")
    liveness_check_failure_threshold = optional(number, 4)
    liveness_check_success_threshold = optional(number, 2)

    # Flexible environment — readiness check (required by provider)
    readiness_check_path              = optional(string, "/")
    readiness_check_check_interval    = optional(string, "5s")
    readiness_check_timeout           = optional(string, "4s")
    readiness_check_failure_threshold = optional(number, 2)
    readiness_check_success_threshold = optional(number, 2)
    readiness_check_app_start_timeout = optional(string, "300s")

    # Traffic split
    traffic_split_enabled  = optional(bool, false)
    traffic_split_shard_by = optional(string, "RANDOM") # COOKIE | IP | RANDOM
    traffic_allocations    = optional(map(string), {})  # { version_id = "weight" }

    # Lifecycle
    noop_on_destroy           = optional(bool, true)
    delete_service_on_destroy = optional(bool, false)
  }))

  default = []

  validation {
    condition     = length(distinct([for s in var.services : s.key])) == length(var.services)
    error_message = "services[*].key values must be unique."
  }

  validation {
    condition     = alltrue([for s in var.services : contains(["standard", "flexible"], s.env_type)])
    error_message = "services[*].env_type must be 'standard' or 'flexible'."
  }

  validation {
    condition     = alltrue([for s in var.services : contains(["automatic", "basic", "manual"], s.scaling_type)])
    error_message = "services[*].scaling_type must be 'automatic', 'basic', or 'manual'."
  }

  validation {
    condition     = alltrue([for s in var.services : contains(["zip", "files", "container"], s.deployment_type)])
    error_message = "services[*].deployment_type must be 'zip', 'files', or 'container'."
  }

  validation {
    condition     = alltrue([for s in var.services : s.env_type == "flexible" || s.deployment_type != "container"])
    error_message = "deployment_type = 'container' is only valid for flexible environment services."
  }

  validation {
    condition     = alltrue([for s in var.services : s.env_type == "standard" || s.scaling_type != "basic"])
    error_message = "scaling_type = 'basic' is only valid for standard environment services."
  }

  validation {
    condition     = alltrue([for s in var.services : s.deployment_type != "zip" || s.deployment_zip_source_url != ""])
    error_message = "services[*].deployment_zip_source_url must be set when deployment_type = 'zip'."
  }

  validation {
    condition     = alltrue([for s in var.services : s.deployment_type != "container" || s.deployment_container_image != ""])
    error_message = "services[*].deployment_container_image must be set when deployment_type = 'container'."
  }

  validation {
    condition     = alltrue([for s in var.services : s.deployment_type != "files" || length(s.deployment_files) > 0])
    error_message = "services[*].deployment_files must not be empty when deployment_type = 'files'."
  }

  validation {
    condition     = alltrue([for s in var.services : !s.traffic_split_enabled || length(s.traffic_allocations) > 0])
    error_message = "services[*].traffic_allocations must not be empty when traffic_split_enabled = true."
  }
}

# ---------------------------------------------------------------------------
# App Engine firewall rules — inbound access control evaluated in
# ascending priority order (lower number = higher precedence).
# ---------------------------------------------------------------------------
variable "firewall_rules" {
  description = "List of App Engine firewall rules. Rules are evaluated in ascending priority order."
  type = list(object({
    key          = string
    priority     = number
    action       = string # "ALLOW" or "DENY"
    source_range = string # CIDR or "*" for all
    description  = optional(string, "")
    create       = optional(bool, true)
  }))

  default = []

  validation {
    condition     = length(distinct([for r in var.firewall_rules : r.key])) == length(var.firewall_rules)
    error_message = "firewall_rules[*].key values must be unique."
  }

  validation {
    condition     = alltrue([for r in var.firewall_rules : contains(["ALLOW", "DENY"], r.action)])
    error_message = "firewall_rules[*].action must be 'ALLOW' or 'DENY'."
  }
}

# ---------------------------------------------------------------------------
# Custom domain mappings for the App Engine application.
# After apply, use the dns_records output to configure your DNS provider.
# ---------------------------------------------------------------------------
variable "domain_mappings" {
  description = "List of custom domain mappings. After apply, add the dns_records output to your DNS provider."
  type = list(object({
    key                 = string
    domain_name         = string
    override_strategy   = optional(string, "STRICT") # "STRICT" or "OVERRIDE"
    ssl_management_type = optional(string, "AUTOMATIC")
    ssl_certificate_id  = optional(string, "")
    create              = optional(bool, true)
  }))

  default = []

  validation {
    condition     = length(distinct([for m in var.domain_mappings : m.key])) == length(var.domain_mappings)
    error_message = "domain_mappings[*].key values must be unique."
  }

  validation {
    condition     = alltrue([for m in var.domain_mappings : contains(["STRICT", "OVERRIDE"], m.override_strategy)])
    error_message = "domain_mappings[*].override_strategy must be 'STRICT' or 'OVERRIDE'."
  }
}

# ---------------------------------------------------------------------------
# URL dispatch rules routing incoming requests to specific services
# by domain and path patterns.
# ---------------------------------------------------------------------------
variable "dispatch_rules" {
  description = "URL dispatch rules routing requests to specific services by domain/path. Applied to the application as a single resource."
  type = list(object({
    domain  = string
    path    = string
    service = string
  }))

  default = []
}
