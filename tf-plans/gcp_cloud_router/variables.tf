# variables.tf

# ---------------------------------------------------------------------------
# Default project for Cloud Router resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID for router definitions."
  type        = string
}

# ---------------------------------------------------------------------------
# Default region for Cloud Router resources.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region for router definitions."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance tags.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with generated metadata labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud Router definitions.
# ---------------------------------------------------------------------------
variable "routers" {
  description = "List of Cloud Router configurations to create."
  type = list(object({
    key     = string
    name    = string
    network = string
    asn     = number

    project_id  = optional(string, "")
    region      = optional(string, "")
    description = optional(string, "")

    keepalive_interval = optional(number, 20)
    advertise_mode     = optional(string, "DEFAULT")
    advertised_groups  = optional(list(string), [])
    advertised_ip_ranges = optional(list(object({
      range       = string
      description = optional(string, "")
    })), [])

    encrypted_interconnect_router = optional(bool, false)

    interfaces = optional(list(object({
      name                    = string
      ip_range                = optional(string, "")
      ip_version              = optional(string, "IPV4")
      vpn_tunnel              = optional(string, "")
      interconnect_attachment = optional(string, "")
      subnetwork              = optional(string, "")
      redundant_interface     = optional(string, "")
    })), [])

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
}
