# main.tf

# ---------------------------------------------------------------------------
# Step 1: Call the reusable GCP VPC network module.
# ---------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/networking/gcp_networks"

  # -------------------------------------------------------------------------
  # Step 2: Provider region and default project passed to the module.
  # -------------------------------------------------------------------------
  region     = var.region
  project_id = var.project_id

  # -------------------------------------------------------------------------
  # Step 3: Common labels — merged with created_date and managed_by so every
  # network carries a consistent, auditable label set.
  # -------------------------------------------------------------------------
  labels = merge(
    var.labels,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  # -------------------------------------------------------------------------
  # Step 4: Networks to create. Each item in the list maps to one VPC network.
  # Per-network fields override module defaults (project_id, routing_mode,
  # mtu, labels, etc.).
  # -------------------------------------------------------------------------
  networks = var.networks
}
