# Step 1: Return instance identifiers from the module.
output "instance_ids" {
  description = "Spanner instance IDs keyed by instance key."
  value       = module.gcp_cloud_spanner.instance_ids
}

# Step 2: Return instance names and configs for integrations.
output "instance_names" {
  description = "Spanner instance names keyed by instance key."
  value       = module.gcp_cloud_spanner.instance_names
}

output "instance_configs" {
  description = "Spanner instance config names keyed by instance key."
  value       = module.gcp_cloud_spanner.instance_configs
}

# Step 3: Return database references.
output "database_ids" {
  description = "Spanner database IDs keyed by <instance_key>--<database_key>."
  value       = module.gcp_cloud_spanner.database_ids
}

output "database_names" {
  description = "Spanner database names keyed by <instance_key>--<database_key>."
  value       = module.gcp_cloud_spanner.database_names
}

# Step 4: Return merged governance tags for audit visibility.
output "common_tags" {
  description = "Merged governance tags used by this wrapper run."
  value       = module.gcp_cloud_spanner.common_tags
}
