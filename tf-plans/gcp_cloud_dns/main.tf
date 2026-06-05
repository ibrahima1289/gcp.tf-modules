# main.tf

# ---------------------------------------------------------------------------
# Step 1: Call the reusable Cloud DNS module.
# ---------------------------------------------------------------------------
module "gcp_cloud_dns" {
  source = "../../modules/networking/gcp_cloud_dns"

  # -------------------------------------------------------------------------
  # Step 2: Default project and region for all zone definitions.
  # -------------------------------------------------------------------------
  project_id = var.project_id
  region     = var.region

  # -------------------------------------------------------------------------
  # Step 3: Merge caller-supplied tags with generated governance metadata.
  # -------------------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  # -------------------------------------------------------------------------
  # Step 4: One or many zone definitions with nested record sets.
  # -------------------------------------------------------------------------
  zones = var.zones
}
