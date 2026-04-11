# variables.tf

# ---------------------------------------------------------------------------
# Default project — can be overridden per network entry.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID. Can be overridden per network via networks[*].project_id."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Region — VPC networks are global but the value is passed to the provider
# and used in labels for traceability.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider. VPC networks are global; this value is used for provider configuration and labels."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common labels — merged into every network.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels merged with per-network labels on every google_compute_network resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networks list — one entry per VPC network to create.
# ---------------------------------------------------------------------------
variable "networks" {
  description = "List of VPC networks to create. Each item maps to one google_compute_network resource."
  type = list(object({
    key         = string # Stable for_each key; must be unique across the list.
    name        = string # VPC network name (lowercase, hyphens, 2–63 chars).
    description = optional(string, "")
    project_id  = optional(string, "") # Per-network project override; falls back to var.project_id.

    # Network mode and routing
    auto_create_subnetworks         = optional(bool, false)        # false = custom mode (recommended).
    routing_mode                    = optional(string, "REGIONAL") # REGIONAL or GLOBAL.
    mtu                             = optional(number, 1460)       # 1300–8896; 1460 = default, 1500 = VLAN attachment.
    delete_default_routes_on_create = optional(bool, false)        # Remove the default 0.0.0.0/0 route on creation.

    # Firewall policy order
    network_firewall_policy_enforcement_order = optional(string, "AFTER_CLASSIC_FIREWALL") # or BEFORE_CLASSIC_FIREWALL.

    # Internal IPv6 (ULA)
    enable_ula_internal_ipv6 = optional(bool, false)
    internal_ipv6_range      = optional(string, "") # /48 ULA range; only used when enable_ula_internal_ipv6 = true.

    # Shared VPC
    shared_vpc_host = optional(bool, false) # Register the project as a Shared VPC host.

    # Per-network labels merged with common labels.
    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for n in var.networks : n.key])) == length(var.networks)
    error_message = "networks[*].key values must be unique."
  }

  validation {
    condition     = length(distinct([for n in var.networks : n.name])) == length(var.networks)
    error_message = "networks[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for n in var.networks : can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", n.name))
    ])
    error_message = "Each network name must be 2–63 characters, start with a lowercase letter, end with a letter or digit, and contain only lowercase letters, digits, or hyphens."
  }

  validation {
    condition = alltrue([
      for n in var.networks : contains(["REGIONAL", "GLOBAL"], n.routing_mode)
    ])
    error_message = "Each network routing_mode must be 'REGIONAL' or 'GLOBAL'."
  }

  validation {
    condition = alltrue([
      for n in var.networks : contains(["AFTER_CLASSIC_FIREWALL", "BEFORE_CLASSIC_FIREWALL"], n.network_firewall_policy_enforcement_order)
    ])
    error_message = "Each network network_firewall_policy_enforcement_order must be 'AFTER_CLASSIC_FIREWALL' or 'BEFORE_CLASSIC_FIREWALL'."
  }

  validation {
    condition = alltrue([
      for n in var.networks : (n.mtu >= 1300 && n.mtu <= 8896)
    ])
    error_message = "Each network mtu must be between 1300 and 8896."
  }
}
