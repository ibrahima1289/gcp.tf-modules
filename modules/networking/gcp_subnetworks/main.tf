# ---------------------------------------------------------------------------
# Subnets: create one or many regional VPC subnets with optional features.
# ---------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  for_each = local.resolved_subnets_map

  # -------------------------------------------------------------------------
  # Step 1: core subnet identity and placement.
  # -------------------------------------------------------------------------
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  network       = each.value.network
  project       = each.value.project_id
  region        = each.value.region

  # -------------------------------------------------------------------------
  # Step 2: optional subnet behavior with safe non-null defaults.
  # -------------------------------------------------------------------------
  description              = each.value.description
  private_ip_google_access = each.value.private_ip_google_access
  purpose                  = each.value.purpose
  stack_type               = each.value.stack_type

  # -------------------------------------------------------------------------
  # Step 3: optional secondary IP ranges for GKE and shared services.
  # -------------------------------------------------------------------------
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  # -------------------------------------------------------------------------
  # Step 4: optional VPC Flow Logs configuration.
  # -------------------------------------------------------------------------
  dynamic "log_config" {
    for_each = each.value.log_config.enabled ? [each.value.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
}
