variable "project_id" {
  description = "Default GCP project ID for all AlloyDB clusters."
  type        = string
}

variable "region" {
  description = "Default GCP region; per-cluster override available via clusters[*].region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with generated metadata into every cluster's labels map."
  type        = map(string)
  default     = {}
}

variable "clusters" {
  description = "List of AlloyDB cluster configurations to create."
  type = list(object({
    key    = string
    name   = string
    region = optional(string, "")
    create = optional(bool, true)

    network      = string
    psc_config   = optional(bool, false)
    cluster_type = optional(string, "PRIMARY")

    automated_backup_enabled         = optional(bool, true)
    automated_backup_start_time      = optional(string, "02:00")
    automated_backup_days_of_week    = optional(list(string), ["MONDAY"])
    automated_backup_retention_count = optional(number, 7)
    automated_backup_retention_days  = optional(number, 0)
    automated_backup_location        = optional(string, "")
    point_in_time_recovery_enabled   = optional(bool, true)

    continuous_backup_enabled         = optional(bool, true)
    continuous_backup_recovery_window = optional(number, 14)

    initial_user     = optional(string, "alloydbadmin")
    initial_password = optional(string, "")

    kms_key_name = optional(string, "")

    maintenance_window_day  = optional(string, "SUNDAY")
    maintenance_window_hour = optional(number, 2)

    deletion_protection = optional(bool, true)
    labels              = optional(map(string), {})

    primary = optional(object({
      instance_id                    = optional(string, "primary")
      cpu_count                      = optional(number, 2)
      availability_type              = optional(string, "REGIONAL")
      database_flags                 = optional(map(string), {})
      require_connectors             = optional(bool, false)
      ssl_mode                       = optional(string, "ENCRYPTED_ONLY")
      enable_public_ip               = optional(bool, false)
      columnar_engine_enabled        = optional(bool, true)
      columnar_engine_memory_size_gb = optional(number, 0)
    }), {})

    read_pools = optional(list(object({
      instance_id        = string
      cpu_count          = optional(number, 2)
      node_count         = optional(number, 1)
      database_flags     = optional(map(string), {})
      require_connectors = optional(bool, false)
      ssl_mode           = optional(string, "ENCRYPTED_ONLY")
      enable_public_ip   = optional(bool, false)
      create             = optional(bool, true)
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for c in var.clusters : c.key])) == length(var.clusters)
    error_message = "clusters[*].key values must be unique."
  }
}
