# Pass project, region, and tags to the module; collect all four resource lists
module "gcp_cloud_monitoring" {
  source                = "../../modules/monitoring_devops/gcp_cloud_monitoring"
  project_id            = var.project_id
  region                = var.region
  notification_channels = var.notification_channels # delivery endpoints for alert notifications
  alert_policies        = var.alert_policies        # threshold, absent, and log-based alert conditions
  uptime_checks         = var.uptime_checks         # periodic HTTP/S or TCP endpoint probes
  dashboards            = local.all_dashboards      # file-based + any inline dashboards from tfvars

  # Merge caller-supplied tags with generated metadata
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
