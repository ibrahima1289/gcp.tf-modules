# outputs.tf

output "router_ids" {
  description = "Cloud Router IDs keyed by router key."
  value       = module.cloud_router.router_ids
}

output "router_names" {
  description = "Cloud Router names keyed by router key."
  value       = module.cloud_router.router_names
}

output "router_self_links" {
  description = "Cloud Router self-links keyed by router key."
  value       = module.cloud_router.router_self_links
}

output "router_regions" {
  description = "Resolved router regions keyed by router key."
  value       = module.cloud_router.router_regions
}

output "router_projects" {
  description = "Resolved router project IDs keyed by router key."
  value       = module.cloud_router.router_projects
}

output "interface_ids" {
  description = "Router interface IDs keyed by '<router_key>/<interface_name>'."
  value       = module.cloud_router.interface_ids
}

output "peer_ids" {
  description = "BGP peer IDs keyed by '<router_key>/<peer_name>'."
  value       = module.cloud_router.peer_ids
}

output "common_tags" {
  description = "Common governance tags metadata returned by the module."
  value       = module.cloud_router.common_tags
}
