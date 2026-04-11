# ---------------------------------------------------------------------------
# Provider region.
# Used as the default region for subnets that do not set a region override.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider and used as the default region for subnet definitions."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Module-wide default project for subnet creation.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default project ID for subnets. Each subnet may override this with its own project_id."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Module-wide default VPC network self link or name.
# ---------------------------------------------------------------------------
variable "network" {
  description = "Default VPC network for subnets. Each subnet may override this with its own network value."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Subnets to create. Supports one or many subnet definitions.
# ---------------------------------------------------------------------------
variable "subnets" {
  description = "List of subnets to create. Each subnet supports overrides for project_id, network, and region."
  type = list(object({
    key                      = string
    name                     = string
    ip_cidr_range            = string
    project_id               = optional(string, "")
    network                  = optional(string, "")
    region                   = optional(string, "")
    description              = optional(string, "")
    private_ip_google_access = optional(bool, false)
    purpose                  = optional(string, "PRIVATE")
    stack_type               = optional(string, "IPV4_ONLY")
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    log_config = optional(object({
      enabled              = optional(bool, false)
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
      }), {
      enabled              = false
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    })
  }))
  default = []

  validation {
    condition     = length(distinct([for s in var.subnets : s.key])) == length(var.subnets)
    error_message = "subnets keys must be unique."
  }

  validation {
    condition     = length(distinct([for s in var.subnets : s.name])) == length(var.subnets)
    error_message = "subnet names must be unique within the module input."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : trimspace(s.name) != ""
    ])
    error_message = "subnets.name cannot be empty."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : can(cidrhost(s.ip_cidr_range, 0))
    ])
    error_message = "Each subnets.ip_cidr_range must be a valid CIDR block."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : (
        trimspace(try(s.project_id, "")) != "" || trimspace(var.project_id) != ""
      )
    ])
    error_message = "Each subnet requires a project_id either on the subnet object or via the module-level project_id variable."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : (
        trimspace(try(s.network, "")) != "" || trimspace(var.network) != ""
      )
    ])
    error_message = "Each subnet requires a network either on the subnet object or via the module-level network variable."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : contains(["PRIVATE", "PRIVATE_SERVICE_CONNECT", "REGIONAL_MANAGED_PROXY", "GLOBAL_MANAGED_PROXY", "PRIVATE_NAT"], s.purpose)
    ])
    error_message = "subnets.purpose must be one of: PRIVATE, PRIVATE_SERVICE_CONNECT, REGIONAL_MANAGED_PROXY, GLOBAL_MANAGED_PROXY, PRIVATE_NAT."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : contains(["IPV4_ONLY", "IPV4_IPV6"], s.stack_type)
    ])
    error_message = "subnets.stack_type must be IPV4_ONLY or IPV4_IPV6."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : alltrue([
        for r in s.secondary_ip_ranges : can(cidrhost(r.ip_cidr_range, 0))
      ])
    ])
    error_message = "Each secondary_ip_ranges.ip_cidr_range must be a valid CIDR block."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : alltrue([
        for r in s.secondary_ip_ranges : trimspace(r.range_name) != ""
      ])
    ])
    error_message = "secondary_ip_ranges.range_name cannot be empty."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : contains(["INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN", "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"], s.log_config.aggregation_interval)
    ])
    error_message = "subnets.log_config.aggregation_interval must be a supported Cloud Logging interval."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : s.log_config.flow_sampling >= 0 && s.log_config.flow_sampling <= 1
    ])
    error_message = "subnets.log_config.flow_sampling must be between 0 and 1."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : contains(["EXCLUDE_ALL_METADATA", "INCLUDE_ALL_METADATA", "CUSTOM_METADATA"], s.log_config.metadata)
    ])
    error_message = "subnets.log_config.metadata must be EXCLUDE_ALL_METADATA, INCLUDE_ALL_METADATA, or CUSTOM_METADATA."
  }
}

# ---------------------------------------------------------------------------
# Common labels/tags tracked in locals for metadata and outputs.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels/tags stored in locals for metadata and outputs."
  type        = map(string)
  default     = {}
}
