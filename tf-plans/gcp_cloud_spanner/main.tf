# Step 1: Call the reusable Cloud Spanner module with one or many instances.
module "gcp_cloud_spanner" {
  source = "../../modules/database/gcp_cloud_spanner"

  project_id = var.project_id # Target project for all resources.
  region     = var.region     # Default region for regional configs.
  instances  = var.instances  # Scalable list for multiple instances/databases.

  # Step 2: Merge caller tags with generated governance metadata.
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
