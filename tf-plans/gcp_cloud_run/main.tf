# ── Call the Cloud Run module ────────────────────────────────────────────────
module "gcp_cloud_run" {
  source     = "../../modules/compute/gcp_cloud_run"
  project_id = var.project_id
  region     = var.region
  services   = var.services
  jobs       = var.jobs

  # Merge caller-supplied tags with Terraform governance labels.
  tags = merge(var.tags, {
    created_date = local.created_date
    managed_by   = "terraform"
  })
}
