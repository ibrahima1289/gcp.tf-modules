# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Creation date materialized at plan time for governance tag stamping.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common tags applied as labels to all versioned resources.
  # ---------------------------------------------------------------------------
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # All services filtered to create = true, with project resolved.
  # Per-service project_id overrides the module default when set.
  # ---------------------------------------------------------------------------
  services_map = {
    for s in var.services : s.key => merge(s, {
      project_id = trimspace(s.project_id) != "" ? s.project_id : var.project_id
    })
    if s.create
  }

  # ---------------------------------------------------------------------------
  # Standard environment services — split from flexible to avoid resource
  # argument conflicts (liveness_check, readiness_check are flexible-only).
  # ---------------------------------------------------------------------------
  standard_services_map = {
    for k, s in local.services_map : k => s
    if s.env_type == "standard"
  }

  # ---------------------------------------------------------------------------
  # Flexible environment services — require liveness and readiness checks.
  # ---------------------------------------------------------------------------
  flexible_services_map = {
    for k, s in local.services_map : k => s
    if s.env_type == "flexible"
  }

  # ---------------------------------------------------------------------------
  # Services with traffic splitting enabled — create split_traffic resource.
  # ---------------------------------------------------------------------------
  split_traffic_map = {
    for k, s in local.services_map : k => s
    if s.traffic_split_enabled
  }

  # ---------------------------------------------------------------------------
  # Firewall rules filtered to create = true.
  # ---------------------------------------------------------------------------
  firewall_rules_map = {
    for r in var.firewall_rules : r.key => r
    if r.create
  }

  # ---------------------------------------------------------------------------
  # Domain mappings filtered to create = true.
  # ---------------------------------------------------------------------------
  domain_mappings_map = {
    for m in var.domain_mappings : m.key => m
    if m.create
  }
}
