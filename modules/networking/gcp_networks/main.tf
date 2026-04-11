# main.tf

# ---------------------------------------------------------------------------
# Step 1: Create VPC networks.
# Each entry in var.networks maps to one google_compute_network resource.
# ---------------------------------------------------------------------------
resource "google_compute_network" "network" {
  for_each = local.resolved_networks_map

  # -------------------------------------------------------------------------
  # Step 2: Core identity — name, description, and project.
  # -------------------------------------------------------------------------
  name        = each.value.name
  description = each.value.description != "" ? each.value.description : null
  project     = each.value.project_id

  # -------------------------------------------------------------------------
  # Step 3: Network mode and routing behavior.
  # auto_create_subnetworks = false creates a custom-mode VPC (recommended).
  # routing_mode GLOBAL routes traffic across all regions via the same
  # network; REGIONAL restricts routing to the originating region.
  # -------------------------------------------------------------------------
  auto_create_subnetworks         = each.value.auto_create_subnetworks
  routing_mode                    = each.value.routing_mode
  mtu                             = each.value.mtu
  delete_default_routes_on_create = each.value.delete_default_routes_on_create

  # -------------------------------------------------------------------------
  # Step 4: Firewall policy enforcement order.
  # Controls whether network firewall policies are evaluated before or after
  # classic VPC firewall rules.
  # -------------------------------------------------------------------------
  network_firewall_policy_enforcement_order = each.value.network_firewall_policy_enforcement_order

  # -------------------------------------------------------------------------
  # Step 5: Internal IPv6 ULA settings.
  # Only applied when enable_ula_internal_ipv6 = true; internal_ipv6_range
  # is optional and left unset when not provided.
  # -------------------------------------------------------------------------
  enable_ula_internal_ipv6 = each.value.enable_ula_internal_ipv6
  internal_ipv6_range      = each.value.enable_ula_internal_ipv6 && each.value.internal_ipv6_range != "" ? each.value.internal_ipv6_range : null

}

# ---------------------------------------------------------------------------
# Step 7: Register projects as Shared VPC host projects.
# One resource is created per unique project_id that has shared_vpc_host = true.
# Depends on network creation to ensure the Compute API is active.
# ---------------------------------------------------------------------------
# resource "google_compute_shared_vpc_host_project" "host" {
#   for_each = local.shared_vpc_host_projects

#   project = each.value

#   depends_on = [google_compute_network.network]
# }
