# Pass project, region, and tags to the Cloud Logging module; forward all four resource lists
module "gcp_cloud_logging" {
  source         = "../../modules/monitoring_devops/gcp_cloud_logging"
  project_id     = var.project_id
  region         = var.region
  log_buckets    = var.log_buckets    # custom log storage containers with retention + Log Analytics
  log_sinks      = var.log_sinks      # export destinations: GCS, BigQuery, Pub/Sub, log bucket
  log_exclusions = var.log_exclusions # project-wide entry drops to reduce ingestion cost
  log_metrics    = var.log_metrics    # log-based metrics for Cloud Monitoring alerting

  # Merge caller-supplied tags with generated metadata labels
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
