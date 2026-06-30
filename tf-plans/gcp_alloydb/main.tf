# Invoke the AlloyDB root module; pass project, region, governance tags, and cluster definitions
module "gcp_alloydb" {
  source = "../../modules/database/gcp_alloyDB"

  project_id = var.project_id # target GCP project
  region     = var.region     # default region; per-cluster override available

  # Merge caller tags with the generated created_date stamp
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  clusters = var.clusters # one or many AlloyDB cluster definitions
}
