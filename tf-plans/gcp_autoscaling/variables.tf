variable "project_id" {
  description = "GCP project ID where all autoscaler resources are created."
  type        = string
}

variable "region" {
  description = "Default GCP region for regional autoscalers."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels applied to all resources."
  type        = map(string)
  default     = {}
}

variable "autoscalers" {
  description = "List of autoscaler configurations. Set region for regional or zone for zonal autoscalers."
  type = list(object({
    key             = string
    create          = optional(bool, true)
    name            = string
    project_id      = optional(string, "")
    region          = optional(string, "")
    zone            = optional(string, "")
    target          = string
    min_replicas    = number
    max_replicas    = number
    cooldown_period = optional(number, 60)
    mode            = optional(string, "ON")
    cpu_utilization = optional(object({
      target            = number
      predictive_method = optional(string, "NONE")
    }), null)
    load_balancing_utilization = optional(object({
      target = number
    }), null)
    metrics = optional(list(object({
      name                       = string
      filter                     = optional(string, "")
      target                     = optional(number, 0)
      type                       = optional(string, "GAUGE")
      single_instance_assignment = optional(number, 0)
    })), [])
    scaling_schedules = optional(list(object({
      name                  = string
      min_required_replicas = number
      schedule              = string
      time_zone             = optional(string, "UTC")
      duration_sec          = optional(number, 3600)
      disabled              = optional(bool, false)
      description           = optional(string, "")
    })), [])
    scale_in_control = optional(object({
      time_window_sec                = optional(number, 300)
      max_scaled_in_replicas_fixed   = optional(number, 0)
      max_scaled_in_replicas_percent = optional(number, 0)
    }), null)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Instance Templates
# Defines the VM configuration (machine type, image, disk, network) for each
# Managed Instance Group. Referenced by regional_migs[*].template_key.
# ---------------------------------------------------------------------------
variable "instance_templates" {
  description = "List of Compute Engine instance templates to create for use by regional MIGs."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    name         = string
    machine_type = optional(string, "e2-medium")
    image        = optional(string, "debian-cloud/debian-12")
    disk_size_gb = optional(number, 20)
    disk_type    = optional(string, "pd-balanced")
    network      = optional(string, "default")
    subnetwork   = optional(string, "")
    tags         = optional(list(string), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for t in var.instance_templates : t.key])) == length(var.instance_templates)
    error_message = "instance_templates[*].key values must be unique."
  }
}

# ---------------------------------------------------------------------------
# Regional Managed Instance Groups (MIGs)
# Creates regional MIGs that the autoscalers will target. Each entry must
# reference an instance template via template_key and optionally links to an
# autoscaler via autoscaler_key so its target is automatically resolved.
# ---------------------------------------------------------------------------
variable "regional_migs" {
  description = "List of regional Managed Instance Groups to create. Use autoscaler_key to link to an autoscaler entry so its target is resolved automatically."
  type = list(object({
    key                = string
    create             = optional(bool, true)
    name               = string
    region             = optional(string, "") # overrides var.region when set
    base_instance_name = string
    template_key       = string # references instance_templates[*].key
    target_size        = optional(number, null)
    autoscaler_key     = optional(string, "") # links to autoscalers[*].key; autoscaler target is set to this MIG's id
  }))
  default = []

  validation {
    condition     = length(distinct([for m in var.regional_migs : m.key])) == length(var.regional_migs)
    error_message = "regional_migs[*].key values must be unique."
  }
}
