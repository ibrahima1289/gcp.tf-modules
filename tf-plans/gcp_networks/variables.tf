# variables.tf

# ---------------------------------------------------------------------------
# Provider region.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider. VPC networks are global; this value configures the provider."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Default project — can be overridden per network.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID for VPC networks. Can be overridden per network via networks[*].project_id."
  type        = string
}

# ---------------------------------------------------------------------------
# Common labels merged into every network.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels merged with per-network labels on every network resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networks list — one entry per VPC network to create.
# ---------------------------------------------------------------------------
variable "networks" {
  description = "List of VPC networks to create. Each item maps to one google_compute_network resource."
  type = list(object({
    key         = string
    name        = string
    description = optional(string, "")
    project_id  = optional(string, "")

    auto_create_subnetworks         = optional(bool, false)
    routing_mode                    = optional(string, "REGIONAL")
    mtu                             = optional(number, 1460)
    delete_default_routes_on_create = optional(bool, false)

    network_firewall_policy_enforcement_order = optional(string, "AFTER_CLASSIC_FIREWALL")

    enable_ula_internal_ipv6 = optional(bool, false)
    internal_ipv6_range      = optional(string, "")

    shared_vpc_host = optional(bool, false)
    labels          = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for n in var.networks : n.key])) == length(var.networks)
    error_message = "networks[*].key values must be unique."
  }
}
