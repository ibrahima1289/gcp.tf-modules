locals {
  # Compute the creation timestamp once; passed into tags for all resources
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # Load dashboard JSON from files; merge with any inline dashboards from tfvars.
  # Add one entry per file under the dashboards/ subdirectory.
  file_dashboards = [
    {
      key            = "app-overview"
      create         = true
      dashboard_json = file("${path.module}/dashboards/app-overview.json")
    },
  ]

  # Merge file-based dashboards with any additional inline ones from var.dashboards.
  # File entries take precedence: var.dashboards entries whose key matches a file entry are dropped.
  all_dashboards = concat(
    local.file_dashboards,
    [for d in var.dashboards : d if !contains([for f in local.file_dashboards : f.key], d.key)]
  )
}
