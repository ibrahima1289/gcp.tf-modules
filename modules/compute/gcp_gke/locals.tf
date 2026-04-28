locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a governance label on all cluster resources.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged into resource_labels on every cluster resource.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Flatten all node pools across all standard (non-autopilot) clusters into
  # a single map keyed by "<cluster_key>/<pool_key>".
  # This produces stable Terraform state addresses independent of list order.
  # Autopilot clusters are excluded — Google manages their nodes automatically.
  # ---------------------------------------------------------------------------
  node_pools_flat = merge([
    for c in var.clusters : {
      for np in c.node_pools :
      "${c.key}/${np.key}" => merge(np, {
        cluster_key = c.key
        location    = trimspace(c.location) != "" ? c.location : var.region
      })
    }
    if c.create && !c.autopilot
  ]...)
}
