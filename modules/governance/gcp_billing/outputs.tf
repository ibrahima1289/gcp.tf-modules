output "project_billing_links" {
  description = "Map of project_id → billing account ID for all active project links."
  value = {
    for k, v in google_billing_project_info.links : k => v.billing_account
  }
}

output "budget_ids" {
  description = "Map of budget key → budget resource name for all active budgets."
  value = {
    for k, v in google_billing_budget.budgets : k => v.id
  }
}

output "budget_names" {
  description = "Map of budget key → display name for all active budgets."
  value = {
    for k, v in google_billing_budget.budgets : k => v.display_name
  }
}

output "iam_binding_ids" {
  description = "Map of role/member → IAM binding ID for all billing account IAM bindings."
  value = {
    for k, v in google_billing_account_iam_member.bindings : k => v.id
  }
}

output "common_labels" {
  description = "Base label map (managed-by, created-date, var.tags) for use on linked resources."
  value       = local.common_labels
}
