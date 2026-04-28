# ---------------------------------------------------------------------------
# Step 1: Create all GKE clusters and node pools defined in var.clusters.
# Standard clusters get separate node pools (Step 3 in the module).
# Autopilot clusters skip node pools — Google manages all nodes.
# Set create = false on any entry whose VPC/subnetwork does not yet exist.
# ---------------------------------------------------------------------------
module "gcp_gke" {
  source     = "../../modules/compute/gcp_gke"
  project_id = var.project_id
  region     = var.region

  clusters = var.clusters

  # Merge caller-supplied tags with generated governance metadata.
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
