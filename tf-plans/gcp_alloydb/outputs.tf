output "cluster_ids" {
  description = "AlloyDB cluster resource IDs keyed by cluster key."
  value       = module.gcp_alloydb.cluster_ids
}

output "cluster_names" {
  description = "AlloyDB cluster IDs (name field) keyed by cluster key."
  value       = module.gcp_alloydb.cluster_names
}

output "primary_instance_ids" {
  description = "Primary instance resource IDs keyed by cluster key."
  value       = module.gcp_alloydb.primary_instance_ids
}

output "primary_instance_names" {
  description = "Primary instance names keyed by cluster key."
  value       = module.gcp_alloydb.primary_instance_names
}

output "primary_ip_addresses" {
  description = "Private IP addresses of primary instances keyed by cluster key."
  value       = module.gcp_alloydb.primary_ip_addresses
}

output "read_pool_ids" {
  description = "Read pool instance resource IDs keyed by <cluster_key>--<instance_id>."
  value       = module.gcp_alloydb.read_pool_ids
}

output "read_pool_ip_addresses" {
  description = "Private IP addresses of read pool instances keyed by composite key."
  value       = module.gcp_alloydb.read_pool_ip_addresses
}

output "cluster_regions" {
  description = "Resolved region for each cluster keyed by cluster key."
  value       = module.gcp_alloydb.cluster_regions
}

output "common_tags" {
  description = "Common governance labels applied by this module call."
  value       = module.gcp_alloydb.common_tags
}
