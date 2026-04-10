output "project_ids" {
  description = "Created project IDs keyed by project_id."
  value       = { for k, m in module.project : k => m.project_id }
}

output "project_numbers" {
  description = "Created project numbers keyed by project_id."
  value       = { for k, m in module.project : k => m.project_number }
}
