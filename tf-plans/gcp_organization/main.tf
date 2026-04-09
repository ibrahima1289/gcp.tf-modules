# ---------------------------------------------------------------------------
# Call the GCP Organization root module.
# Manages IAM members, OrgPolicy v2 constraints, log sinks, and essential
# contacts within an existing Google Cloud Organization.
# ---------------------------------------------------------------------------
module "organization" {
  source = "../../modules/hierarchy/organization"

  # Step 1: Identify the organization by domain or numeric ID (set in tfvars).
  org_domain = var.org_domain
  org_id     = var.org_id

  # Step 2: Set the region for provider configuration.
  region = var.region

  # Step 3: Merge wrapper-level created_date with caller-supplied labels.
  labels = merge(var.labels, {
    created_date = local.created_date
  })

  # Step 4: Apply IAM member grants at the organization level.
  iam_members = var.iam_members

  # Step 5: Apply OrgPolicy v2 constraint policies.
  org_policies = var.org_policies

  # Step 6: Create organization-level log sinks for audit centralization.
  log_sinks = var.log_sinks

  # Step 7: Register essential contacts for Google Cloud notifications.
  essential_contacts = var.essential_contacts
}
