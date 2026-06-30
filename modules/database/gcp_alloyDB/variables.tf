variable "project_id" {
  description = "GCP project ID where all AlloyDB clusters and instances are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "region" {
  description = "Default GCP region for clusters that do not set region explicitly."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with managed_by and created_date into every cluster's labels map."
  type        = map(string)
  default     = {}
}

variable "clusters" {
  description = "List of AlloyDB cluster configurations. Each item creates one cluster with its primary instance and optional read pool instances."
  type = list(object({
    key    = string               # unique stable key for for_each
    name   = string               # cluster ID (must be unique within project + region)
    region = optional(string, "") # falls back to var.region
    create = optional(bool, true) # set false to skip without removing from config

    # Network — AlloyDB is private-IP only; PSA must be pre-configured on the VPC
    network    = string                # VPC self-link or id, e.g. "projects/my-project/global/networks/my-vpc"
    psc_config = optional(bool, false) # enable Private Service Connect instead of PSA

    # Cluster type
    cluster_type = optional(string, "PRIMARY") # PRIMARY | SECONDARY (cross-region replica)

    # Automated backups
    automated_backup_enabled         = optional(bool, true)
    automated_backup_start_time      = optional(string, "02:00") # HH:MM UTC
    automated_backup_days_of_week    = optional(list(string), ["MONDAY"])
    automated_backup_retention_count = optional(number, 7)  # number of backups to retain
    automated_backup_retention_days  = optional(number, 0)  # 0 = use count-based retention
    automated_backup_location        = optional(string, "") # empty = same region as cluster
    point_in_time_recovery_enabled   = optional(bool, true) # enable PITR (requires backup)

    # Continuous backup (PITR window)
    continuous_backup_enabled         = optional(bool, true)
    continuous_backup_recovery_window = optional(number, 14) # days; 1-35

    # Initial database user (created at cluster provisioning time)
    initial_user     = optional(string, "alloydbadmin")
    initial_password = optional(string, "") # set via tfvars or reference a Secret Manager secret

    # Encryption at rest — CMEK (Customer-Managed Encryption Key)
    kms_key_name = optional(string, "") # empty = Google-managed key

    # Maintenance window
    maintenance_window_day  = optional(string, "SUNDAY") # MONDAY…SUNDAY
    maintenance_window_hour = optional(number, 2)        # 0-23 UTC

    # Deletion protection
    deletion_protection = optional(bool, true)

    # Labels merged with common tags
    labels = optional(map(string), {})

    # ── Primary instance ──────────────────────────────────────────────────────
    primary = optional(object({
      instance_id        = optional(string, "primary")        # ID appended to cluster name
      cpu_count          = optional(number, 2)                # 2|4|8|16|64
      availability_type  = optional(string, "REGIONAL")       # REGIONAL (HA) | ZONAL
      database_flags     = optional(map(string), {})          # engine-level flags e.g. max_connections
      require_connectors = optional(bool, false)              # force AlloyDB Auth Proxy
      ssl_mode           = optional(string, "ENCRYPTED_ONLY") # ENCRYPTED_ONLY | ALLOW_UNENCRYPTED_AND_ENCRYPTED
      enable_public_ip   = optional(bool, false)              # AlloyDB supports public IP (preview)
      # Columnar engine (in-memory analytics cache)
      columnar_engine_enabled        = optional(bool, true)
      columnar_engine_memory_size_gb = optional(number, 0) # 0 = auto; set to a fixed GB to override
    }), {})

    # ── Read pool instances ───────────────────────────────────────────────────
    read_pools = optional(list(object({
      instance_id        = string              # unique ID within the cluster
      cpu_count          = optional(number, 2) # vCPUs per node
      node_count         = optional(number, 1) # horizontal scaling: number of read-pool nodes
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

  validation {
    condition     = length(distinct([for c in var.clusters : c.name])) == length(var.clusters)
    error_message = "clusters[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : contains(["PRIMARY", "SECONDARY"], c.cluster_type)
    ])
    error_message = "clusters[*].cluster_type must be PRIMARY or SECONDARY."
  }

  validation {
    condition = alltrue([
      for c in var.clusters : contains(["REGIONAL", "ZONAL"], try(c.primary.availability_type, "REGIONAL"))
    ])
    error_message = "clusters[*].primary.availability_type must be REGIONAL or ZONAL."
  }
}
