# ---------------------------------------------------------------------------
# Provider region.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider and used as the default region for subnets."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common default project ID.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default project ID for subnets."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Common default VPC network.
# ---------------------------------------------------------------------------
variable "network" {
  description = "Default VPC network name or self link for subnets."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Common labels merged with metadata.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels merged with created_date and managed_by metadata."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many subnet definitions.
# ---------------------------------------------------------------------------
variable "subnets" {
  description = "List of subnet definitions to create."
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
    condition = alltrue([
      for s in var.subnets : (
        trimspace(try(s.project_id, "")) != "" || trimspace(var.project_id) != ""
      )
    ])
    error_message = "Each subnet requires a project_id either on the subnet object or via wrapper project_id."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : (
        trimspace(try(s.network, "")) != "" || trimspace(var.network) != ""
      )
    ])
    error_message = "Each subnet requires a network either on the subnet object or via wrapper network."
  }
}
