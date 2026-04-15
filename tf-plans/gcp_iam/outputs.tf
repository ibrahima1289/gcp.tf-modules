output "service_account_ids" {
  description = "Map of service account key to unique ID."
  value       = module.iam.service_account_ids
}

output "service_account_emails" {
  description = "Map of service account key to email address."
  value       = module.iam.service_account_emails
}

output "service_account_names" {
  description = "Map of service account key to fully qualified resource name."
  value       = module.iam.service_account_names
}

output "project_custom_role_ids" {
  description = "Map of custom role key to fully qualified project-scoped role ID."
  value       = module.iam.project_custom_role_ids
}

output "org_custom_role_ids" {
  description = "Map of custom role key to fully qualified organization-scoped role ID."
  value       = module.iam.org_custom_role_ids
}

output "project_binding_etags" {
  description = "Map of binding key to etag of the project IAM binding."
  value       = module.iam.project_binding_etags
}

output "folder_binding_etags" {
  description = "Map of binding key to etag of the folder IAM binding."
  value       = module.iam.folder_binding_etags
}

output "org_binding_etags" {
  description = "Map of binding key to etag of the organization IAM binding."
  value       = module.iam.org_binding_etags
}

output "project_member_etags" {
  description = "Map of member key to etag of the project IAM member binding."
  value       = module.iam.project_member_etags
}

output "folder_member_etags" {
  description = "Map of member key to etag of the folder IAM member binding."
  value       = module.iam.folder_member_etags
}

output "org_member_etags" {
  description = "Map of member key to etag of the organization IAM member binding."
  value       = module.iam.org_member_etags
}

output "common_tags" {
  description = "Common labels applied to resources, including managed_by and created_date."
  value       = module.iam.common_tags
}
