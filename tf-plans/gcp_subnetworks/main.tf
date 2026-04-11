# ---------------------------------------------------------------------------
# Step 1: call the reusable GCP Subnet module.
# ---------------------------------------------------------------------------
module "subnet" {
  source = "../../modules/networking/gcp_subnetworks"

  # -------------------------------------------------------------------------
  # Step 2: shared defaults for provider region, project, and VPC network.
  # -------------------------------------------------------------------------
  region     = var.region
  project_id = var.project_id
  network    = var.network

  # -------------------------------------------------------------------------
  # Step 3: common labels/tags merged with created_date metadata.
  # -------------------------------------------------------------------------
  labels = merge(var.labels, {
    created_date = local.created_date
    managed_by   = "terraform"
  })

  # -------------------------------------------------------------------------
  # Step 4: create one or many subnets with optional per-subnet overrides.
  # -------------------------------------------------------------------------
  subnets = var.subnets
}
