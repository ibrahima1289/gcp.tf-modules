variable "project_id" {
  description = "Default GCP project ID for all Cloud SQL instances."
  type        = string
}

variable "region" {
  description = "Default GCP region; per-instance override available via instances[*].region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance tags merged with generated metadata into every instance's user_labels."
  type        = map(string)
  default     = {}
}

variable "instances" {
  description = "List of Cloud SQL instance configurations to create."
  type = list(object({
    key                 = string # unique stable key for for_each
    name                = string # globally unique instance name
    database_version    = string # MYSQL_8_0 | POSTGRES_15 | SQLSERVER_2022_STANDARD etc.
    region              = optional(string, "")
    deletion_protection = optional(bool, true)
    create              = optional(bool, true)

    tier                  = optional(string, "db-n1-standard-2")
    edition               = optional(string, "ENTERPRISE")
    availability_type     = optional(string, "ZONAL")
    disk_size             = optional(number, 10)
    disk_type             = optional(string, "PD_SSD")
    disk_autoresize       = optional(bool, true)
    disk_autoresize_limit = optional(number, 0)

    backup_enabled                 = optional(bool, true)
    binary_log_enabled             = optional(bool, false)
    point_in_time_recovery_enabled = optional(bool, false)
    backup_start_time              = optional(string, "02:00")
    transaction_log_retention_days = optional(number, 7)
    retained_backups               = optional(number, 7)
    backup_location                = optional(string, "")

    ipv4_enabled    = optional(bool, true)
    require_ssl     = optional(bool, true)
    ssl_mode        = optional(string, "ENCRYPTED_ONLY")
    private_network = optional(string, "")

    authorized_networks = optional(list(object({
      name            = string
      value           = string
      expiration_time = optional(string, "")
    })), [])

    maintenance_window_day          = optional(number, 7)
    maintenance_window_hour         = optional(number, 2)
    maintenance_window_update_track = optional(string, "stable")

    insights_config_enabled = optional(bool, false)
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, false)
    record_client_address   = optional(bool, false)
    query_plans_per_minute  = optional(number, 5)

    database_flags = optional(list(object({
      name  = string
      value = string
    })), [])

    databases = optional(list(object({
      name      = string
      charset   = optional(string, "")
      collation = optional(string, "")
    })), [])

    users = optional(list(object({
      name     = string
      password = optional(string, "")
      host     = optional(string, "%")
      type     = optional(string, "BUILT_IN")
    })), [])

    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for i in var.instances : i.key])) == length(var.instances)
    error_message = "instances[*].key values must be unique."
  }
}
