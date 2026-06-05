variable "project_id" {
  description = "GCP project ID where Cloud Spanner resources are created."
  type        = string
}

variable "region" {
  description = "Default region used by the wrapper and as fallback in module inputs."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance tags passed to the Cloud Spanner module."
  type        = map(string)
  default     = {}
}

variable "instances" {
  description = "List of Cloud Spanner instance definitions passed to the module."
  type = list(object({
    key          = string
    name         = string
    display_name = string
    create       = optional(bool, true)
    region       = optional(string, "")
    config       = optional(string, "")

    capacity_model   = optional(string, "PROCESSING_UNITS")
    processing_units = optional(number, 1000)
    num_nodes        = optional(number, 1)

    instance_edition = optional(string, "STANDARD")
    force_destroy    = optional(bool, false)

    autoscaling = optional(object({
      enabled                               = bool
      min_processing_units                  = number
      max_processing_units                  = number
      high_priority_cpu_utilization_percent = number
      storage_utilization_percent           = number
      }), {
      enabled                               = false
      min_processing_units                  = 1000
      max_processing_units                  = 2000
      high_priority_cpu_utilization_percent = 65
      storage_utilization_percent           = 75
    })

    labels = optional(map(string), {})

    databases = optional(list(object({
      key                      = string
      name                     = string
      create                   = optional(bool, true)
      database_dialect         = optional(string, "GOOGLE_STANDARD_SQL")
      ddl                      = optional(list(string), [])
      version_retention_period = optional(string, "7d")
      deletion_protection      = optional(bool, true)
      enable_drop_protection   = optional(bool, true)
      kms_key_name             = optional(string, "")
    })), [])
  }))
  default = []
}
