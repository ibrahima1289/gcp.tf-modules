# variables.tf

# ---------------------------------------------------------------------------
# Default project for Cloud Router resources. Per-router overrides supported.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used when a router item does not set project_id explicitly."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for Cloud Router resources. Per-router overrides supported.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region used when a router item does not set region explicitly."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance tags applied to all router resources as labels.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with module-generated metadata (managed_by, created_date). Applied as labels on router resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud Router definitions.
# ---------------------------------------------------------------------------
variable "routers" {
  description = "List of Cloud Router configurations to create. Each item creates one router with optional interfaces and BGP peers."
  type = list(object({
    key     = string
    name    = string
    network = string
    asn     = number

    # Placement overrides — empty string resolves to module-level default.
    project_id  = optional(string, "")
    region      = optional(string, "")
    description = optional(string, "")

    # BGP settings
    keepalive_interval = optional(number, 20)
    advertise_mode     = optional(string, "DEFAULT")
    advertised_groups  = optional(list(string), [])
    advertised_ip_ranges = optional(list(object({
      range       = string
      description = optional(string, "")
    })), [])

    # Set to true for encrypted Interconnect integration.
    encrypted_interconnect_router = optional(bool, false)

    # Optional router interfaces (VPN tunnel, Interconnect, or subnetwork).
    interfaces = optional(list(object({
      name                    = string
      ip_range                = optional(string, "")
      ip_version              = optional(string, "IPV4")
      vpn_tunnel              = optional(string, "")
      interconnect_attachment = optional(string, "")
      subnetwork              = optional(string, "")
      redundant_interface     = optional(string, "")
    })), [])

    # Optional BGP peer definitions.
    peers = optional(list(object({
      name                      = string
      interface                 = string
      peer_asn                  = number
      peer_ip_address           = optional(string, "")
      ip_address                = optional(string, "")
      advertised_route_priority = optional(number, 100)
      enable                    = optional(bool, true)
      advertise_mode            = optional(string, "DEFAULT")
      advertised_groups         = optional(list(string), [])
      advertised_ip_ranges = optional(list(object({
        range       = string
        description = optional(string, "")
      })), [])
      # BFD stored as a list so an empty list omits the block without null values.
      bfd = optional(list(object({
        session_initialization_mode = optional(string, "DISABLED")
        min_transmit_interval       = optional(number, 1000)
        min_receive_interval        = optional(number, 1000)
        multiplier                  = optional(number, 5)
      })), [])
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for r in var.routers : r.key])) == length(var.routers)
    error_message = "routers[*].key values must be unique."
  }

  validation {
    condition     = length(distinct([for r in var.routers : r.name])) == length(var.routers)
    error_message = "routers[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for r in var.routers : contains(["DEFAULT", "CUSTOM"], r.advertise_mode)
    ])
    error_message = "Each routers[*].advertise_mode must be DEFAULT or CUSTOM."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.routers : [
        for i in r.interfaces : contains(["IPV4", "IPV6"], i.ip_version)
      ]
    ]))
    error_message = "Each routers[*].interfaces[*].ip_version must be IPV4 or IPV6."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.routers : [
        for p in r.peers : contains(["DEFAULT", "CUSTOM"], p.advertise_mode)
      ]
    ]))
    error_message = "Each routers[*].peers[*].advertise_mode must be DEFAULT or CUSTOM."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.routers : [
        for p in r.peers : [
          for b in p.bfd : contains(["ACTIVE", "PASSIVE", "DISABLED"], b.session_initialization_mode)
        ]
      ]
    ]))
    error_message = "Each routers[*].peers[*].bfd[*].session_initialization_mode must be ACTIVE, PASSIVE, or DISABLED."
  }
}
