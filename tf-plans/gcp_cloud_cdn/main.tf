# ---------------------------------------------------------------------------
# Step 1: Create all Cloud CDN configurations defined in var.* via the module.
# The module manages backend bucket CDN (GCS-backed) and backend service CDN
# (compute / NEG-backed) entries. Set create = false on any entry whose
# GCS bucket or instance groups do not yet exist.
# ---------------------------------------------------------------------------
module "gcp_cloud_cdn" {
  source     = "../../modules/networking/gcp_cloud_cdn"
  project_id = var.project_id

  backend_bucket_cdns  = var.backend_bucket_cdns
  backend_service_cdns = var.backend_service_cdns

  # Merge caller-supplied tags with generated metadata.
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
