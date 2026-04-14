# main.tf

# ---------------------------------------------------------------------------
# Step 1: Create Cloud Routers keyed by stable key for deterministic mapping.
# ---------------------------------------------------------------------------
resource "google_compute_router" "router" {
  for_each = local.routers_map

  # -------------------------------------------------------------------------
  # Step 2: Core router identity, placement, and VPC network binding.
  # -------------------------------------------------------------------------
  name        = each.value.name
  description = each.value.description
  project     = each.value.project_id
  region      = each.value.region
  network     = each.value.network

  # -------------------------------------------------------------------------
  # Step 4: Enable encrypted Interconnect support when requested.
  # -------------------------------------------------------------------------
  encrypted_interconnect_router = each.value.encrypted_interconnect_router

  # -------------------------------------------------------------------------
  # Step 5: BGP configuration block for dynamic route exchange.
  # -------------------------------------------------------------------------
  bgp {
    asn                = each.value.asn
    keepalive_interval = each.value.keepalive_interval
    advertise_mode     = each.value.advertise_mode

    # Advertised groups are only valid in CUSTOM advertise_mode.
    advertised_groups = each.value.advertise_mode == "CUSTOM" ? each.value.advertised_groups : []

    # -----------------------------------------------------------------------
    # Step 6: Custom advertised IP ranges — only active in CUSTOM mode.
    # -----------------------------------------------------------------------
    dynamic "advertised_ip_ranges" {
      for_each = each.value.advertise_mode == "CUSTOM" ? each.value.advertised_ip_ranges : []
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Step 7: Create optional router interfaces.
# Each interface links the router to a VPN tunnel, Interconnect attachment,
# or subnetwork (for Cloud Router Appliance). Keyed by
# "<router_key>/<interface_name>" for stable for_each addressing.
# ---------------------------------------------------------------------------
resource "google_compute_router_interface" "interface" {
  for_each = local.interfaces_map

  # -------------------------------------------------------------------------
  # Step 8: Interface identity and router reference.
  # -------------------------------------------------------------------------
  name    = each.value.iface.name
  router  = google_compute_router.router[each.value.router_key].name
  project = each.value.project_id
  region  = each.value.region

  # -------------------------------------------------------------------------
  # Step 9: Interface IP range and attachment target.
  # Provide one of: vpn_tunnel, interconnect_attachment, or subnetwork.
  # Empty strings are treated as omitted (not passed to the provider).
  # -------------------------------------------------------------------------
  ip_range                = trimspace(each.value.iface.ip_range) != "" ? each.value.iface.ip_range : null
  vpn_tunnel              = trimspace(each.value.iface.vpn_tunnel) != "" ? each.value.iface.vpn_tunnel : null
  interconnect_attachment = trimspace(each.value.iface.interconnect_attachment) != "" ? each.value.iface.interconnect_attachment : null
  subnetwork              = trimspace(each.value.iface.subnetwork) != "" ? each.value.iface.subnetwork : null
  ip_version              = each.value.iface.ip_version
  redundant_interface     = trimspace(each.value.iface.redundant_interface) != "" ? each.value.iface.redundant_interface : null
}

# ---------------------------------------------------------------------------
# Step 10: Create optional BGP peers.
# Peers establish BGP sessions with on-premises or remote routers.
# Keyed by "<router_key>/<peer_name>". Depends on interfaces being ready.
# ---------------------------------------------------------------------------
resource "google_compute_router_peer" "peer" {
  for_each = local.peers_map

  depends_on = [google_compute_router_interface.interface]

  # -------------------------------------------------------------------------
  # Step 11: Peer identity, router binding, and interface attachment.
  # -------------------------------------------------------------------------
  name      = each.value.peer.name
  router    = google_compute_router.router[each.value.router_key].name
  project   = each.value.project_id
  region    = each.value.region
  interface = each.value.peer.interface

  # -------------------------------------------------------------------------
  # Step 12: BGP peer addressing and remote AS number.
  # -------------------------------------------------------------------------
  peer_asn        = each.value.peer.peer_asn
  peer_ip_address = trimspace(each.value.peer.peer_ip_address) != "" ? each.value.peer.peer_ip_address : null
  ip_address      = trimspace(each.value.peer.ip_address) != "" ? each.value.peer.ip_address : null

  # -------------------------------------------------------------------------
  # Step 13: Route priority and peer enable/disable state.
  # -------------------------------------------------------------------------
  advertised_route_priority = each.value.peer.advertised_route_priority
  enable                    = each.value.peer.enable

  # -------------------------------------------------------------------------
  # Step 14: Optional custom route advertisement for this peer.
  # -------------------------------------------------------------------------
  advertise_mode    = each.value.peer.advertise_mode
  advertised_groups = each.value.peer.advertise_mode == "CUSTOM" ? each.value.peer.advertised_groups : []

  dynamic "advertised_ip_ranges" {
    for_each = each.value.peer.advertise_mode == "CUSTOM" ? each.value.peer.advertised_ip_ranges : []
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }

  # -------------------------------------------------------------------------
  # Step 15: Optional BFD (Bidirectional Forwarding Detection) configuration.
  # Stored as a list(object) so an empty list omits the block cleanly.
  # -------------------------------------------------------------------------
  dynamic "bfd" {
    for_each = each.value.peer.bfd
    content {
      session_initialization_mode = bfd.value.session_initialization_mode
      min_transmit_interval       = bfd.value.min_transmit_interval
      min_receive_interval        = bfd.value.min_receive_interval
      multiplier                  = bfd.value.multiplier
    }
  }
}
