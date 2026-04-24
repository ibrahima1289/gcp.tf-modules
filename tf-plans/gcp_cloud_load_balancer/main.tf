# ---------------------------------------------------------------------------
# Step 1: Create all load balancers defined in var.* through the module.
# The module creates the full resource stack for each enabled LB type:
# global HTTP(S) LBs, regional HTTP(S) LBs, external NLBs, internal NLBs.
# Backend instance groups must exist before applying this plan.
# ---------------------------------------------------------------------------
module "gcp_cloud_load_balancer" {
  source     = "../../modules/networking/gcp_cloud_load_balancer"
  project_id = var.project_id
  region     = var.region

  global_http_lbs   = var.global_http_lbs
  regional_http_lbs = var.regional_http_lbs
  network_lbs       = var.network_lbs
  internal_lbs      = var.internal_lbs

  # Merge caller-supplied tags with generated metadata
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
