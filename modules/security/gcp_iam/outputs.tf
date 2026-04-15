output "service_account_ids" {
  description = "Map of service account key to unique ID."
  value       = { for k, v in google_service_account.sa : k => v.unique_id }
}

output "service_account_emails" {
  description = "Map of service account key to email address (used in IAM member strings as 'serviceAccount:<email>')."
  value       = { for k, v in google_service_account.sa : k => v.email }
}

output "service_account_names" {
  description = "Map of service account key to fully qualified resource name (projects/{project}/serviceAccounts/{email})."
  value       = { for k, v in google_service_account.sa : k => v.name }
}

output "project_custom_role_ids" {
  description = "Map of custom role key to fully qualified project-scoped role ID (projects/{project}/roles/{role_id})."
  value       = { for k, v in google_project_iam_custom_role.role : k => v.id }
}

output "org_custom_role_ids" {
  description = "Map of custom role key to fully qualified organization-scoped role ID (organizations/{org}/roles/{role_id})."
  value       = { for k, v in google_organization_iam_custom_role.role : k => v.id }
}

output "project_binding_etags" {
  description = "Map of binding key to etag of the project IAM binding (changes with each update)."
  value       = { for k, v in google_project_iam_binding.binding : k => v.etag }
}

output "folder_binding_etags" {
  description = "Map of binding key to etag of the folder IAM binding (changes with each update)."
  value       = { for k, v in google_folder_iam_binding.binding : k => v.etag }
}

output "org_binding_etags" {
  description = "Map of binding key to etag of the organization IAM binding (changes with each update)."
  value       = { for k, v in google_organization_iam_binding.binding : k => v.etag }
}

output "project_member_etags" {
  description = "Map of member key to etag of the project IAM member binding (changes with each update)."
  value       = { for k, v in google_project_iam_member.member : k => v.etag }
}

output "folder_member_etags" {
  description = "Map of member key to etag of the folder IAM member binding (changes with each update)."
  value       = { for k, v in google_folder_iam_member.member : k => v.etag }
}

output "org_member_etags" {
  description = "Map of member key to etag of the organization IAM member binding (changes with each update)."
  value       = { for k, v in google_organization_iam_member.member : k => v.etag }
}

output "common_tags" {
  description = "Common labels merged from module defaults and var.tags, including managed_by and created_date."
  value       = local.common_tags
}
