variable "project_id" {
  description = "GCP project ID where all Cloud SQL instances are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "region" {
  description = "Default GCP region for instances that do not set region explicitly."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance tags merged with managed_by and created_date into every instance's user_labels."
  type        = map(string)
  default     = {}
}

variable "instances" {
  description = "List of Cloud SQL instance configurations. Each item creates one instance with its databases and users."
  type = list(object({
    key                 = string               # unique stable key for for_each
    name                = string               # globally unique instance name
    database_version    = string               # MYSQL_8_0 | POSTGRES_15 | SQLSERVER_2022_STANDARD etc.
    region              = optional(string, "") # falls back to var.region
    deletion_protection = optional(bool, true)
    create              = optional(bool, true)

    # Machine tier and edition
    tier    = optional(string, "db-n1-standard-2") # e.g. db-f1-micro, db-n1-standard-2
    edition = optional(string, "ENTERPRISE")       # ENTERPRISE | ENTERPRISE_PLUS

    # Availability and storage
    availability_type     = optional(string, "ZONAL")  # ZONAL | REGIONAL (HA)
    disk_size             = optional(number, 10)       # GB; min 10
    disk_type             = optional(string, "PD_SSD") # PD_SSD | PD_HDD
    disk_autoresize       = optional(bool, true)
    disk_autoresize_limit = optional(number, 0) # 0 = unlimited

    # Backup configuration
    backup_enabled                 = optional(bool, true)
    binary_log_enabled             = optional(bool, false) # MySQL only
    point_in_time_recovery_enabled = optional(bool, false) # PostgreSQL / SQL Server
    backup_start_time              = optional(string, "02:00")
    transaction_log_retention_days = optional(number, 7)
    retained_backups               = optional(number, 7)
    backup_location                = optional(string, "") # empty = same region

    # IP and connectivity
    ipv4_enabled    = optional(bool, true) # enable public IP
    require_ssl     = optional(bool, true)
    private_network = optional(string, "")               # VPC self-link for private IP; empty = disabled
    ssl_mode        = optional(string, "ENCRYPTED_ONLY") # ALLOW_UNENCRYPTED_AND_ENCRYPTED | ENCRYPTED_ONLY | TRUSTED_CLIENT_CERTIFICATE_REQUIRED

    # Authorized networks (public IP access rules)
    authorized_networks = optional(list(object({
      name            = string
      value           = string               # CIDR
      expiration_time = optional(string, "") # RFC 3339 or empty
    })), [])

    # Maintenance window
    maintenance_window_day          = optional(number, 7)        # 1=Mon … 7=Sun
    maintenance_window_hour         = optional(number, 2)        # 0-23 UTC
    maintenance_window_update_track = optional(string, "stable") # canary | stable

    # Query Insights
    insights_config_enabled = optional(bool, false)
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, false)
    record_client_address   = optional(bool, false)
    query_plans_per_minute  = optional(number, 5)

    # Database flags (engine-specific parameters)
    database_flags = optional(list(object({
      name  = string
      value = string
    })), [])

    # Databases to create inside this instance
    databases = optional(list(object({
      name      = string
      charset   = optional(string, "") # empty = engine default
      collation = optional(string, "") # empty = engine default
    })), [])

    # Users to create inside this instance
    users = optional(list(object({
      name     = string
      password = optional(string, "")         # set via tfvars or Secret Manager; empty = no password set
      host     = optional(string, "%")        # MySQL only; % = any host
      type     = optional(string, "BUILT_IN") # BUILT_IN | CLOUD_IAM_USER | CLOUD_IAM_SERVICE_ACCOUNT | CLOUD_IAM_GROUP
    })), [])

    # Additional user labels merged with common tags
    labels = optional(map(string), {})
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
      for i in var.instances : contains(["ZONAL", "REGIONAL"], i.availability_type)
    ])
    error_message = "instances[*].availability_type must be ZONAL or REGIONAL."
  }

  validation {
    condition = alltrue([
      for i in var.instances : contains(["PD_SSD", "PD_HDD"], i.disk_type)
    ])
    error_message = "instances[*].disk_type must be PD_SSD or PD_HDD."
  }

  validation {
    condition = alltrue([
      for i in var.instances : contains(["ENTERPRISE", "ENTERPRISE_PLUS"], i.edition)
    ])
    error_message = "instances[*].edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }

  validation {
    condition = alltrue([
      for i in var.instances : contains(
        ["ALLOW_UNENCRYPTED_AND_ENCRYPTED", "ENCRYPTED_ONLY", "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"],
        i.ssl_mode
      )
    ])
    error_message = "instances[*].ssl_mode must be ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY, or TRUSTED_CLIENT_CERTIFICATE_REQUIRED."
  }
}
