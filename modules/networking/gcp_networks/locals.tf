# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Timestamp used for the created_date label on every network.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels applied to every google_compute_network resource.
  # Per-network labels are merged on top in main.tf.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.labels
  )

  # ---------------------------------------------------------------------------
  # Keyed map of all network input objects for for_each.
  # ---------------------------------------------------------------------------
  networks_map = {
    for n in var.networks : n.key => n
  }

  # ---------------------------------------------------------------------------
  # Resolved networks: fills in the default project_id where not overridden.
  # ---------------------------------------------------------------------------
  resolved_networks_map = {
    for key, n in local.networks_map : key => merge(n, {
      project_id = n.project_id != "" ? n.project_id : var.project_id
    })
  }

  # ---------------------------------------------------------------------------
  # Networks where shared_vpc_host = true, deduplicated by project_id.
  # One google_compute_shared_vpc_host_project resource is created per
  # unique project, regardless of how many networks belong to that project.
  # ---------------------------------------------------------------------------
  shared_vpc_host_projects = toset([
    for key, n in local.resolved_networks_map : n.project_id
    if n.shared_vpc_host
  ])
}
