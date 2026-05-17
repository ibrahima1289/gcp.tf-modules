# ---------------------------------------------------------------------------
# Step 1: Deploy all VM instances defined in var.vms through the module.
# The module creates one google_compute_instance per enabled entry, plus
# any additional data disks. Backend instance groups must be created after
# VMs when used with a load balancer.
# ---------------------------------------------------------------------------
module "gcp_vm" {
  source     = "../../modules/compute/gcp_vm"
  project_id = var.project_id
  region     = var.region
  vms        = var.vms

  # Merge caller-supplied tags with generated governance metadata.
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
