project_id = "main-project-492903"
region     = "us-central1"

tags = {
  owner       = "network-team"
  environment = "production"
  team        = "network"
}

# ── External Peer Gateways ─────────────────────────────────────────────────────
# Define the remote VPN endpoints first. vpn_gateways reference them by key.

peer_gateways = [

  # On-premises datacenter firewall with two public IPs for redundancy
  {
    key             = "on-prem-dc1"
    name            = "on-prem-dc1-peer"
    description     = "Primary datacenter Cisco ASA firewall — two interface IPs"
    redundancy_type = "TWO_IPS_REDUNDANCY"
    interfaces = [
      { id = 0, ip_address = "203.0.113.1" }, # primary WAN IP of on-prem device
      { id = 1, ip_address = "203.0.113.2" }, # secondary WAN IP of on-prem device
    ]
    create = true
  },

  # AWS Virtual Private Gateway — four IPs for FOUR_IPS_REDUNDANCY (two tunnels × 2)
  # Set create = true once AWS VGW public IPs are available
  {
    key             = "aws-vgw"
    name            = "aws-us-east-1-vgw-peer"
    description     = "AWS VGW in us-east-1 — four tunnel endpoints for full HA VPN"
    redundancy_type = "FOUR_IPS_REDUNDANCY"
    interfaces = [
      { id = 0, ip_address = "52.0.0.1" },
      { id = 1, ip_address = "52.0.0.2" },
      { id = 2, ip_address = "52.0.0.3" },
      { id = 3, ip_address = "52.0.0.4" },
    ]
    create = false # enable once AWS VGW IPs are provisioned
  },
]

# ── HA VPN Gateways ────────────────────────────────────────────────────────────
# Each gateway creates two external IPs and the tunnels defined inline.
# Pre-requisite: the Cloud Router referenced in each tunnel must already exist.

vpn_gateways = [

  # ── Production ↔ On-premises HA VPN ─────────────────────────────────────────
  # Two-tunnel active/active pair to on-prem-dc1 for 99.99% SLA.
  {
    key              = "prod-to-dc1"
    name             = "prod-ha-vpn-dc1"
    network          = "projects/main-project-492903/global/networks/prod-vpc"
    region           = "us-central1"
    peer_gateway_key = "on-prem-dc1"
    create           = true

    tunnels = [
      # Tunnel 0: GCP interface 0 ↔ peer interface 0 (primary path)
      {
        key                             = "tunnel-0"
        name                            = "prod-dc1-tunnel-0"
        vpn_gateway_interface           = 0
        peer_external_gateway_interface = 0
        shared_secret                   = "REPLACE_WITH_SECRET_0" # use Secret Manager in production
        ike_version                     = 2
        router                          = "prod-cloud-router" # must exist before apply
        router_interface_name           = "prod-dc1-if-0"
        router_bgp_ip_range             = "169.254.1.1/30" # local BGP IP on Cloud Router
        bgp_peer_name                   = "prod-dc1-peer-0"
        bgp_peer_ip                     = "169.254.1.2" # remote BGP IP on on-prem device
        bgp_peer_asn                    = 65001         # on-premises AS number
        advertised_route_priority       = 100
        bfd = {
          session_initialization_mode = "ACTIVE"
          min_transmit_interval       = 1000
          min_receive_interval        = 1000
          multiplier                  = 5
        }
      },
      # Tunnel 1: GCP interface 1 ↔ peer interface 1 (secondary/failover path)
      {
        key                             = "tunnel-1"
        name                            = "prod-dc1-tunnel-1"
        vpn_gateway_interface           = 1
        peer_external_gateway_interface = 1
        shared_secret                   = "REPLACE_WITH_SECRET_1"
        ike_version                     = 2
        router                          = "prod-cloud-router"
        router_interface_name           = "prod-dc1-if-1"
        router_bgp_ip_range             = "169.254.2.1/30"
        bgp_peer_name                   = "prod-dc1-peer-1"
        bgp_peer_ip                     = "169.254.2.2"
        bgp_peer_asn                    = 65001
        advertised_route_priority       = 100
      },
    ]
  },

  # ── Staging ↔ On-premises HA VPN ────────────────────────────────────────────
  # Single tunnel pair for staging — lower priority than prod path.
  # Set create = true when staging VPC and Cloud Router are ready.
  {
    key              = "staging-to-dc1"
    name             = "staging-ha-vpn-dc1"
    network          = "projects/main-project-492903/global/networks/staging-vpc"
    region           = "us-central1"
    peer_gateway_key = "on-prem-dc1"
    create           = false # enable when staging Cloud Router exists

    tunnels = [
      {
        key                             = "tunnel-0"
        name                            = "staging-dc1-tunnel-0"
        vpn_gateway_interface           = 0
        peer_external_gateway_interface = 0
        shared_secret                   = "REPLACE_WITH_STAGING_SECRET_0"
        router                          = "staging-cloud-router"
        router_interface_name           = "staging-dc1-if-0"
        router_bgp_ip_range             = "169.254.10.1/30"
        bgp_peer_name                   = "staging-dc1-peer-0"
        bgp_peer_ip                     = "169.254.10.2"
        bgp_peer_asn                    = 65001
        advertised_route_priority       = 200 # lower priority than prod path
      },
      {
        key                             = "tunnel-1"
        name                            = "staging-dc1-tunnel-1"
        vpn_gateway_interface           = 1
        peer_external_gateway_interface = 1
        shared_secret                   = "REPLACE_WITH_STAGING_SECRET_1"
        router                          = "staging-cloud-router"
        router_interface_name           = "staging-dc1-if-1"
        router_bgp_ip_range             = "169.254.11.1/30"
        bgp_peer_name                   = "staging-dc1-peer-1"
        bgp_peer_ip                     = "169.254.11.2"
        bgp_peer_asn                    = 65001
        advertised_route_priority       = 200
      },
    ]
  },
]
