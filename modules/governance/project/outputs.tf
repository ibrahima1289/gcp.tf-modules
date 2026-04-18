# outputs.tf

output "project_id" {
  description = "Project ID for the primary project (project_id input)."
  value       = local.created_project_ids[var.project_id]
}

output "project_number" {
  description = "Project number for the primary project (project_id input)."
  value       = local.created_project_numbers[var.project_id]
}

output "project_ids" {
  description = "All created project IDs keyed by project_id."
  value       = local.created_project_ids
}

output "project_numbers" {
  description = "All created project numbers keyed by project_id."
  value       = local.created_project_numbers
}
