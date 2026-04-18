module "gcp_cloud_sql" {
  source = "../../modules/database/gcp_cloud_sql"

  project_id = var.project_id # default project for all instances
  region     = var.region     # default region; per-instance override available

  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  instances = var.instances # one or many Cloud SQL instance definitions
}
