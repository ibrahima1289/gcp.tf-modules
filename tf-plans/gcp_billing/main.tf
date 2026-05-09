# ===========================================================================
# Cloud Billing deployment plan — invokes the gcp_billing module with
# project links, budgets, and IAM bindings defined in terraform.tfvars.
# ===========================================================================
module "billing" {
  source = "../../modules/governance/gcp_billing"

  # Billing account and project context.
  billing_account_id = var.billing_account_id
  project_id         = var.project_id
  region             = var.region

  # Base labels forwarded to module common_labels output.
  tags = merge(local.extra_tags, var.tags)

  # Projects to link to the billing account.
  project_links = var.project_links

  # Spend budgets with alerting configuration.
  budgets = var.budgets

  # Additive IAM bindings on the billing account.
  iam_bindings = var.iam_bindings
}
