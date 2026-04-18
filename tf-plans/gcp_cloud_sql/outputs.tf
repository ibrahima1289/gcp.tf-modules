output "instance_ids" {
  description = "Cloud SQL instance resource IDs keyed by instance key."
  value       = module.gcp_cloud_sql.instance_ids
}

output "instance_names" {
  description = "Cloud SQL instance names keyed by instance key."
  value       = module.gcp_cloud_sql.instance_names
}

output "instance_connection_names" {
  description = "Cloud SQL connection names (project:region:instance) for Cloud SQL Auth Proxy."
  value       = module.gcp_cloud_sql.instance_connection_names
}

output "public_ip_addresses" {
  description = "Public IP addresses keyed by instance key."
  value       = module.gcp_cloud_sql.public_ip_addresses
}

output "private_ip_addresses" {
  description = "Private IP addresses keyed by instance key."
  value       = module.gcp_cloud_sql.private_ip_addresses
}

output "database_ids" {
  description = "Database resource IDs keyed by <instance_key>--<db_name>."
  value       = module.gcp_cloud_sql.database_ids
}

output "user_ids" {
  description = "User resource IDs keyed by <instance_key>--<user_name>."
  value       = module.gcp_cloud_sql.user_ids
}

output "instance_regions" {
  description = "Resolved region for each instance keyed by instance key."
  value       = module.gcp_cloud_sql.instance_regions
}

output "common_tags" {
  description = "Common governance tags applied by this module call."
  value       = module.gcp_cloud_sql.common_tags
}
