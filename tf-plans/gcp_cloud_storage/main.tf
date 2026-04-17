# main.tf

# ---------------------------------------------------------------------------
# Step 1: Call the reusable Cloud Storage module.
# ---------------------------------------------------------------------------
module "cloud_storage" {
  source = "../../modules/storage/gcp_cloud_storage"

  # -------------------------------------------------------------------------
  # Step 2: Default project and region applied to all bucket definitions that
  # do not specify their own project_id or location override.
  # -------------------------------------------------------------------------
  project_id = var.project_id
  region     = var.region

  # -------------------------------------------------------------------------
  # Step 3: Common governance tags merged with created_date and managed_by.
  # These are stamped as labels on every bucket.
  # -------------------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  # -------------------------------------------------------------------------
  # Step 4: One or many bucket definitions forwarded from the wrapper variable.
  # -------------------------------------------------------------------------
  buckets = var.buckets
}
