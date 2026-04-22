# ---------------------------------------------------------------------------
# Step 1: HA VPN Gateways
# Each gateway is an active/active pair with two external IP interfaces.
# HA VPN requires BGP (Cloud Router) and provides a 99.99% availability SLA.
# ---------------------------------------------------------------------------
resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  for_each = local.ha_gateways_map

  project    = each.value.project_id
  name       = each.value.name
  region     = each.value.region
  network    = each.value.network    # VPC network this gateway attaches to
  stack_type = each.value.stack_type # IPV4_ONLY | IPV4_IPV6

  # Optional VPN gateway description
  dynamic "vpn_interfaces" {
    for_each = each.value.interconnect_attachments
    content {
      id                      = vpn_interfaces.value.id
      interconnect_attachment = vpn_interfaces.value.interconnect_attachment
    }
  }
}

# ---------------------------------------------------------------------------
# Step 2: External Peer Gateways
# Represents the remote endpoint — on-premises hardware, AWS VGW, or Azure.
# A single external gateway can have 1, 2, or 4 interface IPs for redundancy.
# ---------------------------------------------------------------------------
resource "google_compute_external_vpn_gateway" "peer_gateway" {
  for_each = local.peer_gateways_map

  project         = each.value.project_id
  name            = each.value.name
  description     = each.value.description
  redundancy_type = each.value.redundancy_type # SINGLE_IP_INTERNALLY_REDUNDANT | TWO_IPS_REDUNDANCY | FOUR_IPS_REDUNDANCY

  dynamic "interface" {
    for_each = each.value.interfaces
    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

# ---------------------------------------------------------------------------
# Step 3: VPN Tunnels
# Each tunnel is one IPsec connection between an HA VPN gateway interface and
# a specific peer interface. HA VPN requires two tunnels (one per interface)
# to achieve the 99.99% SLA. Tunnels are keyed as "<gateway>/<tunnel>".
# ---------------------------------------------------------------------------
resource "google_compute_vpn_tunnel" "tunnel" {
  for_each = local.tunnels_flat_map

  project = each.value.project_id
  name    = each.value.name
  region  = each.value.region
  router  = each.value.router # existing Cloud Router resource name

  # HA VPN gateway binding
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway[each.value.gateway_key].id
  vpn_gateway_interface = each.value.vpn_gateway_interface # 0 or 1 — maps to the HA gateway interface

  # Peer gateway binding; mutually exclusive: external peer OR another GCP HA gateway
  peer_external_gateway           = each.value.peer_gateway_key != "" ? google_compute_external_vpn_gateway.peer_gateway[each.value.peer_gateway_key].id : null
  peer_external_gateway_interface = each.value.peer_gateway_key != "" ? each.value.peer_external_gateway_interface : null

  shared_secret = each.value.shared_secret # pre-shared key; use Secret Manager in production
  ike_version   = each.value.ike_version   # IKEv2 strongly recommended
}

# ---------------------------------------------------------------------------
# Step 4: Cloud Router Interfaces
# A virtual interface on the Cloud Router creates the local BGP endpoint for
# each tunnel. The IP must be from a /30 or /29 link-local range per tunnel.
# ---------------------------------------------------------------------------
resource "google_compute_router_interface" "router_interface" {
  for_each = local.tunnels_flat_map

  project    = each.value.project_id
  region     = each.value.region
  name       = each.value.router_interface_name
  router     = each.value.router              # must match the router used by the tunnel
  ip_range   = each.value.router_bgp_ip_range # e.g. "169.254.1.1/30" — link-local /30
  vpn_tunnel = google_compute_vpn_tunnel.tunnel[each.key].name
}

# ---------------------------------------------------------------------------
# Step 5: BGP Peers
# Establishes the BGP session between the Cloud Router interface and the
# remote peer IP. Routes are exchanged automatically after the session forms.
# ---------------------------------------------------------------------------
resource "google_compute_router_peer" "bgp_peer" {
  for_each = local.tunnels_flat_map

  project                   = each.value.project_id
  region                    = each.value.region
  name                      = each.value.bgp_peer_name
  router                    = each.value.router
  interface                 = google_compute_router_interface.router_interface[each.key].name
  peer_ip_address           = each.value.bgp_peer_ip               # remote BGP peer IP (e.g. "169.254.1.2")
  peer_asn                  = each.value.bgp_peer_asn              # remote AS number
  advertised_route_priority = each.value.advertised_route_priority # lower = preferred; default 100

  # Optional: enable BFD for sub-second failure detection
  dynamic "bfd" {
    for_each = each.value.bfd != null ? [each.value.bfd] : []
    content {
      session_initialization_mode = bfd.value.session_initialization_mode # ACTIVE | PASSIVE | DISABLED
      min_transmit_interval       = bfd.value.min_transmit_interval
      min_receive_interval        = bfd.value.min_receive_interval
      multiplier                  = bfd.value.multiplier
    }
  }

  # Optional: advertise custom route ranges to the peer instead of the default all-subnets
  dynamic "advertised_ip_ranges" {
    for_each = each.value.advertised_ip_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
}
