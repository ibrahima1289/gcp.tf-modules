variable "project_id" {
  description = "GCP project ID where all Cloud Spanner resources are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "region" {
  description = "Default region used to derive a regional Spanner config when instances[*].config is not set."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with managed_by and created_date into every Spanner instance label map."
  type        = map(string)
  default     = {}
}

variable "instances" {
  description = "List of Cloud Spanner instance definitions. Supports one or many instances and one or many databases per instance."
  type = list(object({
    key          = string
    name         = string
    display_name = string
    create       = optional(bool, true)

    # Region/config controls.
    region = optional(string, "")
    config = optional(string, "")

    # Capacity model controls.
    capacity_model   = optional(string, "PROCESSING_UNITS") # PROCESSING_UNITS | NODES
    processing_units = optional(number, 1000)
    num_nodes        = optional(number, 1)

    # Instance behavior and edition.
    instance_edition = optional(string, "STANDARD") # STANDARD | ENTERPRISE | ENTERPRISE_PLUS
    force_destroy    = optional(bool, false)

    # Optional autoscaling for processing-unit instances.
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

    # Database definitions under each instance.
    databases = optional(list(object({
      key                      = string
      name                     = string
      create                   = optional(bool, true)
      database_dialect         = optional(string, "GOOGLE_STANDARD_SQL") # GOOGLE_STANDARD_SQL | POSTGRESQL
      ddl                      = optional(list(string), [])
      version_retention_period = optional(string, "7d")
      deletion_protection      = optional(bool, true)
      enable_drop_protection   = optional(bool, true)
      kms_key_name             = optional(string, "")
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for i in var.instances : i.key])) == length(var.instances)
    error_message = "instances[*].key values must be unique."
  }

  validation {
    condition     = length(distinct([for i in var.instances : i.name])) == length(var.instances)
    error_message = "instances[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for i in var.instances : contains(["PROCESSING_UNITS", "NODES"], i.capacity_model)
    ])
    error_message = "instances[*].capacity_model must be PROCESSING_UNITS or NODES."
  }

  validation {
    condition = alltrue([
      for i in var.instances : contains(["STANDARD", "ENTERPRISE", "ENTERPRISE_PLUS"], i.instance_edition)
    ])
    error_message = "instances[*].instance_edition must be STANDARD, ENTERPRISE, or ENTERPRISE_PLUS."
  }

  validation {
    condition = alltrue([
      for i in var.instances : i.processing_units >= 100
    ])
    error_message = "instances[*].processing_units must be >= 100."
  }

  validation {
    condition = alltrue([
      for i in var.instances : i.num_nodes >= 1
    ])
    error_message = "instances[*].num_nodes must be >= 1."
  }
}
