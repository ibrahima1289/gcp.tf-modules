# main.tf

# ---------------------------------------------------------------------------
# Step 1: Call the reusable Cloud Router module.
# ---------------------------------------------------------------------------
module "cloud_router" {
  source = "../../modules/networking/gcp_cloud_router"

  # -------------------------------------------------------------------------
  # Step 2: Default project and region for all router definitions.
  # -------------------------------------------------------------------------
  project_id = var.project_id
  region     = var.region

  # -------------------------------------------------------------------------
  # Step 3: Common tags merged with created_date and managed_by metadata.
  # -------------------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  # -------------------------------------------------------------------------
  # Step 4: One or many router definitions passed through to the module.
  # -------------------------------------------------------------------------
  routers = var.routers
}
