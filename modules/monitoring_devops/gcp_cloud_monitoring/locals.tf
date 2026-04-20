locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # Common labels applied to every labelable resource created by this module
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # Notification channels map — excludes create = false entries
  channels_map = {
    for c in var.notification_channels : c.key => c
    if c.create
  }

  # Alert policies map — excludes create = false entries
  alert_policies_map = {
    for p in var.alert_policies : p.key => p
    if p.create
  }

  # Uptime checks map — excludes create = false entries
  uptime_checks_map = {
    for u in var.uptime_checks : u.key => u
    if u.create
  }

  # Dashboards map — excludes create = false entries
  dashboards_map = {
    for d in var.dashboards : d.key => d
    if d.create
  }
}
