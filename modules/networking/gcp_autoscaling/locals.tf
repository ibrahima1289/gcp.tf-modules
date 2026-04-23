locals {
  # ---------------------------------------------------------------------------
  # Creation date used for governance metadata.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged into outputs for all module resources.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Regional autoscalers — entries where region is set (and zone is empty).
  # Resolves project_id and region to the module defaults when not overridden.
  # ---------------------------------------------------------------------------
  regional_autoscalers_map = {
    for a in var.autoscalers : a.key => merge(a, {
      project_id = trimspace(a.project_id) != "" ? a.project_id : var.project_id
      region     = trimspace(a.region) != "" ? a.region : var.region
    })
    if a.create && trimspace(a.region) != ""
  }

  # ---------------------------------------------------------------------------
  # Zonal autoscalers — entries where zone is set (and region is empty).
  # Resolves project_id to the module default when not overridden.
  # ---------------------------------------------------------------------------
  zonal_autoscalers_map = {
    for a in var.autoscalers : a.key => merge(a, {
      project_id = trimspace(a.project_id) != "" ? a.project_id : var.project_id
    })
    if a.create && trimspace(a.zone) != ""
  }
}
