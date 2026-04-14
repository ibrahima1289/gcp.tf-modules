# terraform.tfvars

# ---------------------------------------------------------------------------
# Default placement
# ---------------------------------------------------------------------------
project_id = "main-project"
region     = "us-central1"

# ---------------------------------------------------------------------------
# Common metadata tags
# ---------------------------------------------------------------------------
tags = {
  owner       = "network-team"
  environment = "shared"
}

# ---------------------------------------------------------------------------
# Example 1: Cloud Router for HA VPN with two redundant interfaces and peers.
# Example 2: Cloud Router with custom route advertisement for Interconnect.
# ---------------------------------------------------------------------------
routers = [
  {
    key         = "vpn-router-central"
    name        = "vpn-router-central"
    network     = "projects/main-project/global/networks/platform-shared-vpc"
    asn         = 65001
    description = "Cloud Router for HA VPN to on-premises data center"

    interfaces = [
      {
        name       = "if-vpn-central-1"
        ip_range   = "169.254.0.1/30"
        vpn_tunnel = "projects/main-project/regions/us-central1/vpnTunnels/vpn-tunnel-01"
      },
      {
        name                = "if-vpn-central-2"
        ip_range            = "169.254.0.5/30"
        vpn_tunnel          = "projects/main-project/regions/us-central1/vpnTunnels/vpn-tunnel-02"
        redundant_interface = "if-vpn-central-1"
      }
    ]

    peers = [
      {
        name            = "peer-onprem-1"
        interface       = "if-vpn-central-1"
        peer_asn        = 65002
        peer_ip_address = "169.254.0.2"
        ip_address      = "169.254.0.1"
        bfd = [
          {
            session_initialization_mode = "ACTIVE"
            min_transmit_interval       = 1000
            min_receive_interval        = 1000
            multiplier                  = 5
          }
        ]
      },
      {
        name            = "peer-onprem-2"
        interface       = "if-vpn-central-2"
        peer_asn        = 65002
        peer_ip_address = "169.254.0.6"
        ip_address      = "169.254.0.5"
      }
    ]
  },
  {
    key            = "custom-advert-router"
    name           = "custom-advert-router"
    network        = "projects/main-project/global/networks/platform-shared-vpc"
    asn            = 65003
    description    = "Router with custom route advertisement for Interconnect connectivity"
    advertise_mode = "CUSTOM"

    advertised_groups = ["ALL_SUBNETS"]

    advertised_ip_ranges = [
      {
        range       = "192.168.100.0/24"
        description = "On-premises management CIDR"
      }
    ]
  }
]
