# Step 1: Call the GCP IAM module.
module "iam" {
  source = "../../modules/security/gcp_iam"

  # Step 2: Pass the default project ID.
  project_id = var.project_id

  # Step 3: Pass merged tags including the deployment date and managed_by label.
  tags = merge(var.tags, { created_date = local.created_date, managed_by = "terraform" })

  # Step 4: Pass service accounts configuration.
  service_accounts = var.service_accounts

  # Step 5: Pass custom roles configuration.
  custom_roles = var.custom_roles

  # Step 6: Pass authoritative IAM bindings configuration.
  bindings = var.bindings

  # Step 7: Pass additive IAM members configuration.
  members = var.members
}
