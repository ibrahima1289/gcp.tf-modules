# main.tf

# ---------------------------------------------------------------------------
# Step 1: Create DNS managed zones.
# Visibility, DNSSEC, private network binding, forwarding targets, and
# peering config are all emitted via dynamic blocks to avoid null arguments.
# ---------------------------------------------------------------------------
resource "google_dns_managed_zone" "zone" {
  for_each = local.zones_map

  project     = each.value.project_id
  name        = each.value.name
  dns_name    = each.value.dns_name
  description = each.value.description
  labels      = each.value.labels

  # Public zones are internet-resolvable; all others are private-visibility.
  visibility = contains(["private", "forwarding", "peering"], each.value.zone_type) ? "private" : "public"

  # ---------------------------------------------------------------------------
  # Step 2: Enable DNSSEC on public zones when requested.
  # Protects against DNS spoofing and cache-poisoning attacks.
  # ---------------------------------------------------------------------------
  dynamic "dnssec_config" {
    for_each = each.value.zone_type == "public" && each.value.dnssec_enabled ? [1] : []
    content {
      state         = "on"
      non_existence = each.value.dnssec_non_existence
    }
  }

  # ---------------------------------------------------------------------------
  # Step 3: Bind private / forwarding / peering zones to specific VPC networks.
  # Only emitted when private_visibility_networks is non-empty.
  # ---------------------------------------------------------------------------
  dynamic "private_visibility_config" {
    for_each = contains(["private", "forwarding", "peering"], each.value.zone_type) && length(each.value.private_visibility_networks) > 0 ? [1] : []
    content {
      dynamic "networks" {
        for_each = each.value.private_visibility_networks
        content {
          network_url = networks.value
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Step 4: Configure forwarding targets for forwarding zones.
  # Queries for this domain are sent to the specified upstream resolvers.
  # ---------------------------------------------------------------------------
  dynamic "forwarding_config" {
    for_each = each.value.zone_type == "forwarding" && length(each.value.forwarding_targets) > 0 ? [1] : []
    content {
      dynamic "target_name_servers" {
        for_each = each.value.forwarding_targets
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Step 5: Configure peering for zones that delegate to another VPC's zone.
  # ---------------------------------------------------------------------------
  dynamic "peering_config" {
    for_each = each.value.zone_type == "peering" && trimspace(each.value.peering_target_network) != "" ? [1] : []
    content {
      target_network {
        network_url = each.value.peering_target_network
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Step 6: Create simple DNS record sets (no routing policy).
# Keyed by "<zone_key>--<record_key>" for stable Terraform state.
# ---------------------------------------------------------------------------
resource "google_dns_record_set" "simple" {
  for_each = local.records_simple

  project      = each.value.project_id
  name         = each.value.record_name
  type         = each.value.type
  ttl          = each.value.ttl
  managed_zone = google_dns_managed_zone.zone[each.value.zone_key].name
  rrdatas      = each.value.rrdatas
}

# ---------------------------------------------------------------------------
# Step 7: Create DNS record sets with a routing policy (WRR or GEO).
# rrdatas must not be set when routing_policy is active — these records
# live in a separate resource to prevent argument conflicts.
# ---------------------------------------------------------------------------
resource "google_dns_record_set" "routed" {
  for_each = local.records_routed

  project      = each.value.project_id
  name         = each.value.record_name
  type         = each.value.type
  ttl          = each.value.ttl
  managed_zone = google_dns_managed_zone.zone[each.value.zone_key].name

  routing_policy {
    # Weighted round-robin: distribute traffic proportionally across targets.
    # enable_geo_fencing conflicts with wrr, so it is omitted for WRR policies.
    dynamic "wrr" {
      for_each = each.value.routing_policy.type == "WRR" ? each.value.routing_policy.wrr_targets : []
      content {
        weight  = wrr.value.weight
        rrdatas = wrr.value.rrdatas
      }
    }

    # Geolocation: return different answers based on resolver region.
    # enable_geo_fencing is only valid inside a GEO policy block.
    dynamic "geo" {
      for_each = each.value.routing_policy.type == "GEO" ? each.value.routing_policy.geo_targets : []
      content {
        location = geo.value.location
        rrdatas  = geo.value.rrdatas
      }
    }

    # enable_geo_fencing is only set for GEO policies; conflicts with wrr block.
    enable_geo_fencing = each.value.routing_policy.type == "GEO" ? each.value.routing_policy.enable_geo_fencing : null
  }
}
