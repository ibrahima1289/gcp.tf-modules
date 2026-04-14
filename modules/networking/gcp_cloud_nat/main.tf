# main.tf

# ---------------------------------------------------------------------------
# Step 1: Create Cloud Routers only for NAT entries that requested router
# creation. Each router is tied to the NAT key for deterministic mapping.
# ---------------------------------------------------------------------------
resource "google_compute_router" "router" {
  for_each = local.create_router_map

  # -------------------------------------------------------------------------
  # Step 2: Core router identity and placement.
  # -------------------------------------------------------------------------
  name        = each.value.router_name
  description = each.value.router_description
  project     = each.value.project_id
  region      = each.value.region
  network     = each.value.network

  # -------------------------------------------------------------------------
  # Step 3: BGP settings for hybrid/dynamic routing integration.
  # -------------------------------------------------------------------------
  bgp {
    asn                = each.value.router_asn
    keepalive_interval = each.value.router_keepalive_interval
  }
}

# ---------------------------------------------------------------------------
# Step 4: Create NAT resources with standard (non-dynamic) port allocation.
# ---------------------------------------------------------------------------
resource "google_compute_router_nat" "nat_standard" {
  for_each = local.nats_dynamic_disabled

  # -------------------------------------------------------------------------
  # Step 5: Core NAT identity and router binding.
  # If create_router=true, bind to the router created in Step 1.
  # Otherwise, bind to the existing router name supplied in inputs.
  # -------------------------------------------------------------------------
  name    = each.value.name
  project = each.value.project_id
  region  = each.value.region
  router  = each.value.create_router ? google_compute_router.router[each.key].name : each.value.router

  # -------------------------------------------------------------------------
  # Step 6: NAT IP allocation mode and optional manual IP lists.
  # -------------------------------------------------------------------------
  nat_ip_allocate_option = each.value.nat_ip_allocate_option
  nat_ips                = each.value.nat_ip_allocate_option == "MANUAL_ONLY" ? each.value.nat_ips : []
  drain_nat_ips          = each.value.drain_nat_ips

  # -------------------------------------------------------------------------
  # Step 7: NAT scope and timeout behavior.
  # -------------------------------------------------------------------------
  source_subnetwork_ip_ranges_to_nat  = each.value.source_subnetwork_ip_ranges_to_nat
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping
  enable_dynamic_port_allocation      = false
  min_ports_per_vm                    = each.value.min_ports_per_vm
  udp_idle_timeout_sec                = each.value.udp_idle_timeout_sec
  icmp_idle_timeout_sec               = each.value.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec    = each.value.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec     = each.value.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec           = each.value.tcp_time_wait_timeout_sec

  # -------------------------------------------------------------------------
  # Step 8: Optional per-subnetwork NAT selection.
  # Only used when source_subnetwork_ip_ranges_to_nat=LIST_OF_SUBNETWORKS.
  # -------------------------------------------------------------------------
  dynamic "subnetwork" {
    for_each = each.value.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? each.value.subnetworks : []
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = subnetwork.value.secondary_ip_range_names
    }
  }

  # -------------------------------------------------------------------------
  # Step 9: Optional NAT logging configuration.
  # -------------------------------------------------------------------------
  dynamic "log_config" {
    for_each = each.value.log_config_enable ? [1] : []
    content {
      enable = true
      filter = each.value.log_config_filter
    }
  }
}

# ---------------------------------------------------------------------------
# Step 10: Create NAT resources with dynamic port allocation enabled.
# ---------------------------------------------------------------------------
resource "google_compute_router_nat" "nat_dynamic" {
  for_each = local.nats_dynamic_enabled

  # -------------------------------------------------------------------------
  # Step 11: Core NAT identity and router binding.
  # -------------------------------------------------------------------------
  name    = each.value.name
  project = each.value.project_id
  region  = each.value.region
  router  = each.value.create_router ? google_compute_router.router[each.key].name : each.value.router

  # -------------------------------------------------------------------------
  # Step 12: NAT IP allocation and drain list.
  # -------------------------------------------------------------------------
  nat_ip_allocate_option = each.value.nat_ip_allocate_option
  nat_ips                = each.value.nat_ip_allocate_option == "MANUAL_ONLY" ? each.value.nat_ips : []
  drain_nat_ips          = each.value.drain_nat_ips

  # -------------------------------------------------------------------------
  # Step 13: Dynamic port allocation and timeout behavior.
  # -------------------------------------------------------------------------
  source_subnetwork_ip_ranges_to_nat  = each.value.source_subnetwork_ip_ranges_to_nat
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping
  enable_dynamic_port_allocation      = true
  min_ports_per_vm                    = each.value.min_ports_per_vm
  max_ports_per_vm                    = each.value.max_ports_per_vm
  udp_idle_timeout_sec                = each.value.udp_idle_timeout_sec
  icmp_idle_timeout_sec               = each.value.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec    = each.value.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec     = each.value.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec           = each.value.tcp_time_wait_timeout_sec

  # -------------------------------------------------------------------------
  # Step 14: Optional per-subnetwork NAT selection.
  # -------------------------------------------------------------------------
  dynamic "subnetwork" {
    for_each = each.value.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? each.value.subnetworks : []
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = subnetwork.value.secondary_ip_range_names
    }
  }

  # -------------------------------------------------------------------------
  # Step 15: Optional NAT logging configuration.
  # -------------------------------------------------------------------------
  dynamic "log_config" {
    for_each = each.value.log_config_enable ? [1] : []
    content {
      enable = true
      filter = each.value.log_config_filter
    }
  }
}
