variable "project_id" {
  description = "GCP project ID where all Cloud VPN resources are created."
  type        = string
}

variable "region" {
  description = "GCP region for all VPN resources."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels applied to all resources."
  type        = map(string)
  default     = {}
}

variable "peer_gateways" {
  description = "List of external peer gateway configurations."
  type = list(object({
    key             = string
    create          = optional(bool, true)
    name            = string
    description     = optional(string, "")
    project_id      = optional(string, "")
    redundancy_type = optional(string, "TWO_IPS_REDUNDANCY")
    interfaces = list(object({
      id         = number
      ip_address = string
    }))
  }))
  default = []
}

variable "vpn_gateways" {
  description = "List of HA VPN gateway configurations with inline tunnel, router interface, and BGP peer definitions."
  type = list(object({
    key              = string
    create           = optional(bool, true)
    name             = string
    network          = string
    project_id       = optional(string, "")
    region           = optional(string, "")
    stack_type       = optional(string, "IPV4_ONLY")
    peer_gateway_key = optional(string, "")
    interconnect_attachments = optional(list(object({
      id                      = number
      interconnect_attachment = string
    })), [])
    tunnels = list(object({
      key                             = string
      name                            = string
      vpn_gateway_interface           = number
      peer_external_gateway_interface = optional(number, 0)
      shared_secret                   = string
      ike_version                     = optional(number, 2)
      router                          = string
      router_interface_name           = string
      router_bgp_ip_range             = string
      bgp_peer_name                   = string
      bgp_peer_ip                     = string
      bgp_peer_asn                    = number
      advertised_route_priority       = optional(number, 100)
      bfd = optional(object({
        session_initialization_mode = optional(string, "ACTIVE")
        min_transmit_interval       = optional(number, 1000)
        min_receive_interval        = optional(number, 1000)
        multiplier                  = optional(number, 5)
      }), null)
      advertised_ip_ranges = optional(list(object({
        range       = string
        description = optional(string, "")
      })), [])
    }))
  }))
  default = []
}
