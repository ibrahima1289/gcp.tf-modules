# main.tf

# ---------------------------------------------------------------------------
# Step 1: Call the reusable App Engine module.
# ---------------------------------------------------------------------------
module "gcp_app_engine" {
  source = "../../modules/compute/gcp_app_engine"

  # -------------------------------------------------------------------------
  # Step 2: Default project for the application and all service versions.
  # -------------------------------------------------------------------------
  project_id = var.project_id
  region     = var.region

  # -------------------------------------------------------------------------
  # Step 3: Merge caller-supplied tags with generated governance metadata.
  # -------------------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  # -------------------------------------------------------------------------
  # Step 4: App Engine application (singleton per project).
  # -------------------------------------------------------------------------
  application = var.application

  # -------------------------------------------------------------------------
  # Step 5: One or many service version definitions.
  # -------------------------------------------------------------------------
  services = var.services

  # -------------------------------------------------------------------------
  # Step 6: Optional firewall rules, domain mappings, and dispatch rules.
  # -------------------------------------------------------------------------
  firewall_rules  = var.firewall_rules
  domain_mappings = var.domain_mappings
  dispatch_rules  = var.dispatch_rules
}
