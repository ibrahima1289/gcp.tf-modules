output "project_billing_links" {
  description = "Map of project_id → billing account ID for all active project links."
  value       = module.billing.project_billing_links
}

output "budget_ids" {
  description = "Map of budget key → resource name for all active budgets."
  value       = module.billing.budget_ids
}

output "budget_names" {
  description = "Map of budget key → display name for all active budgets."
  value       = module.billing.budget_names
}

output "iam_binding_ids" {
  description = "Map of role/member → binding ID for all IAM bindings."
  value       = module.billing.iam_binding_ids
}

output "common_labels" {
  description = "Base label map (managed-by, created-date, var.tags)."
  value       = module.billing.common_labels
}
