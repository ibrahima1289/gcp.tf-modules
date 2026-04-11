locals {
  # ---------------------------------------------------------------------------
  # Created date stamp for metadata and traceability.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels/tags tracked as metadata for this module.
  # ---------------------------------------------------------------------------
  common_labels = merge(var.labels, {
    created_date = local.created_date
    managed_by   = "terraform"
  })

  # ---------------------------------------------------------------------------
  # Convert subnet input list to a map for stable for_each identity.
  # ---------------------------------------------------------------------------
  subnets_map = {
    for subnet in var.subnets : subnet.key => subnet
  }

  # ---------------------------------------------------------------------------
  # Resolve defaults for project, network, and region per subnet.
  # ---------------------------------------------------------------------------
  resolved_subnets_map = {
    for key, subnet in local.subnets_map : key => merge(subnet, {
      project_id = trimspace(subnet.project_id) != "" ? subnet.project_id : var.project_id
      network    = trimspace(subnet.network) != "" ? subnet.network : var.network
      region     = trimspace(subnet.region) != "" ? subnet.region : var.region
    })
  }
}
