# ---------------------------------------------------------------------------
# Default project for all VPN resources. Per-gateway overrides are supported.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used when a gateway entry does not set project_id explicitly."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for all VPN resources.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region used when a gateway entry does not set region explicitly."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance tags merged into module outputs and labels where supported.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# HA VPN Gateways
# Each entry creates one HA VPN gateway with two external IP interfaces.
# Tunnels are defined inline; peer gateways are referenced by peer_gateway_key.
# ---------------------------------------------------------------------------
variable "vpn_gateways" {
  description = "List of HA VPN gateway configurations. Each entry creates one gateway and all its associated tunnels, router interfaces, and BGP peers."
  type = list(object({
    key        = string
    create     = optional(bool, true)
    name       = string
    network    = string                        # VPC network self-link or name
    project_id = optional(string, "")          # overrides var.project_id when set
    region     = optional(string, "")          # overrides var.region when set
    stack_type = optional(string, "IPV4_ONLY") # IPV4_ONLY | IPV4_IPV6

    # Optional: attach gateway interfaces to Dedicated Interconnect VLAN attachments
    # (used when HA VPN over Interconnect is required for encryption on Interconnect)
    interconnect_attachments = optional(list(object({
      id                      = number # 0 or 1
      interconnect_attachment = string # full self-link to the VLAN attachment
    })), [])

    # Key referencing an entry in var.peer_gateways; empty = peer is another GCP HA gateway
    peer_gateway_key = optional(string, "")

    # Tunnels for this gateway (typically 2 for HA VPN — one per gateway interface)
    tunnels = list(object({
      key                             = string
      name                            = string
      vpn_gateway_interface           = number              # 0 or 1 — local HA gateway interface
      peer_external_gateway_interface = optional(number, 0) # peer interface index
      shared_secret                   = string              # pre-shared key; use Secret Manager in production
      ike_version                     = optional(number, 2)

      # Existing Cloud Router to attach this tunnel's BGP session to
      router = string # resource name of the Cloud Router (must be in the same region)

      # BGP interface created on the Cloud Router for this tunnel
      router_interface_name = string
      router_bgp_ip_range   = string # link-local CIDR for the local BGP endpoint, e.g. "169.254.1.1/30"

      # BGP peer settings
      bgp_peer_name = string
      bgp_peer_ip   = string # remote peer IP, e.g. "169.254.1.2"
      bgp_peer_asn  = number # remote AS number

      advertised_route_priority = optional(number, 100) # lower = preferred during failover

      # Optional BFD configuration for sub-second failure detection
      bfd = optional(object({
        session_initialization_mode = optional(string, "ACTIVE") # ACTIVE | PASSIVE | DISABLED
        min_transmit_interval       = optional(number, 1000)     # milliseconds
        min_receive_interval        = optional(number, 1000)     # milliseconds
        multiplier                  = optional(number, 5)        # detection multiplier
      }), null)

      # Optional: advertise specific route ranges instead of all subnets
      advertised_ip_ranges = optional(list(object({
        range       = string
        description = optional(string, "")
      })), [])
    }))
  }))
  default = []

  validation {
    condition     = length(distinct([for g in var.vpn_gateways : g.key])) == length(var.vpn_gateways)
    error_message = "vpn_gateways[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for g in var.vpn_gateways : contains(["IPV4_ONLY", "IPV4_IPV6"], g.stack_type)
    ])
    error_message = "vpn_gateways[*].stack_type must be IPV4_ONLY or IPV4_IPV6."
  }
}

# ---------------------------------------------------------------------------
# External Peer Gateways
# Represent on-premises devices or other-cloud VPN endpoints.
# Referenced from vpn_gateways[*].peer_gateway_key.
# ---------------------------------------------------------------------------
variable "peer_gateways" {
  description = "List of external peer gateway configurations representing on-premises or other-cloud VPN endpoints."
  type = list(object({
    key             = string
    create          = optional(bool, true)
    name            = string
    description     = optional(string, "")
    project_id      = optional(string, "")
    redundancy_type = optional(string, "TWO_IPS_REDUNDANCY") # SINGLE_IP_INTERNALLY_REDUNDANT | TWO_IPS_REDUNDANCY | FOUR_IPS_REDUNDANCY

    # Interface IPs of the remote VPN device (1 for SINGLE, 2 for TWO, 4 for FOUR)
    interfaces = list(object({
      id         = number # 0-based index
      ip_address = string # public IP of the peer device interface
    }))
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.peer_gateways : p.key])) == length(var.peer_gateways)
    error_message = "peer_gateways[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for p in var.peer_gateways : contains(
        ["SINGLE_IP_INTERNALLY_REDUNDANT", "TWO_IPS_REDUNDANCY", "FOUR_IPS_REDUNDANCY"],
        p.redundancy_type
      )
    ])
    error_message = "peer_gateways[*].redundancy_type must be SINGLE_IP_INTERNALLY_REDUNDANT, TWO_IPS_REDUNDANCY, or FOUR_IPS_REDUNDANCY."
  }
}
