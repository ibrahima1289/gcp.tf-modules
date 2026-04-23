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
