# ── Call the Pub/Sub module ──────────────────────────────────────────────────
module "gcp_pubsub" {
  source        = "../../modules/app_development/Pub_Sub"
  project_id    = var.project_id
  region        = var.region
  schemas       = var.schemas
  topics        = var.topics
  subscriptions = var.subscriptions

  # Merge caller-supplied tags with Terraform governance labels.
  tags = merge(var.tags, {
    created_date = local.created_date
    managed_by   = "terraform"
  })
}
