# Pass-through output: folder names in folders/<id> format.
output "folder_resource_names" {
  description = "Map of folders key to folder resource name (folders/<id>)."
  value       = module.folder.folder_resource_names
}

# Pass-through output: numeric folder IDs.
output "folder_ids" {
  description = "Map of folders key to numeric folder ID."
  value       = module.folder.folder_ids
}

# Pass-through output: display names.
output "folder_display_names" {
  description = "Map of folders key to folder display name."
  value       = module.folder.folder_display_names
}

# Pass-through output: IAM member IDs.
output "folder_iam_member_ids" {
  description = "Map of folder IAM member key to resource ID."
  value       = module.folder.folder_iam_member_ids
}

# Pass-through output: policy names.
output "folder_policy_names" {
  description = "Map of folder policy key to policy resource name."
  value       = module.folder.folder_policy_names
}

# Pass-through output: sink names.
output "folder_log_sink_names" {
  description = "Map of folder log sink key to sink name."
  value       = module.folder.folder_log_sink_names
}

# Pass-through output: sink writer identities.
output "folder_log_sink_writer_identities" {
  description = "Map of folder log sink key to writer identity."
  value       = module.folder.folder_log_sink_writer_identities
}

# Pass-through output: essential contact IDs.
output "folder_essential_contact_ids" {
  description = "Map of folder essential contact key to contact resource ID."
  value       = module.folder.folder_essential_contact_ids
}

# Pass-through output: common labels.
output "common_labels" {
  description = "Common labels map merged with created_date and managed_by."
  value       = module.folder.common_labels
}
