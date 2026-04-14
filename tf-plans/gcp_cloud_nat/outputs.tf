# outputs.tf

output "nat_ids" {
  description = "Cloud NAT IDs keyed by NAT key."
  value       = module.cloud_nat.nat_ids
}

output "nat_names" {
  description = "Cloud NAT names keyed by NAT key."
  value       = module.cloud_nat.nat_names
}

output "nat_router_names" {
  description = "Effective router names used by each NAT key."
  value       = module.cloud_nat.nat_router_names
}

output "created_router_names" {
  description = "Routers created by the module, keyed by NAT key."
  value       = module.cloud_nat.created_router_names
}

output "nat_regions" {
  description = "Resolved NAT regions keyed by NAT key."
  value       = module.cloud_nat.nat_regions
}

output "nat_projects" {
  description = "Resolved project IDs keyed by NAT key."
  value       = module.cloud_nat.nat_projects
}

output "common_tags" {
  description = "Common governance tags metadata returned by the module."
  value       = module.cloud_nat.common_tags
}
