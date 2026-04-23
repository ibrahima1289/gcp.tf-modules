# ---------------------------------------------------------------------------
# Step 1: Pass all autoscaler configurations to the autoscaling module.
# Managed Instance Groups must exist before applying this plan — provision
# them separately using google_compute_region_instance_group_manager or
# google_compute_instance_group_manager.
# ---------------------------------------------------------------------------
module "gcp_autoscaling" {
  source      = "../../modules/networking/gcp_autoscaling"
  project_id  = var.project_id
  region      = var.region
  autoscalers = var.autoscalers

  # Merge caller-supplied tags with generated metadata
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
