# outputs.tf

output "router_ids" {
  description = "Cloud Router resource IDs keyed by router key."
  value       = { for k, r in google_compute_router.router : k => r.id }
}

output "router_names" {
  description = "Cloud Router names keyed by router key."
  value       = { for k, r in google_compute_router.router : k => r.name }
}

output "router_self_links" {
  description = "Cloud Router self-links keyed by router key."
  value       = { for k, r in google_compute_router.router : k => r.self_link }
}

output "router_regions" {
  description = "Resolved router regions keyed by router key."
  value       = { for k, r in local.routers_map : k => r.region }
}

output "router_projects" {
  description = "Resolved router project IDs keyed by router key."
  value       = { for k, r in local.routers_map : k => r.project_id }
}

output "interface_ids" {
  description = "Router interface IDs keyed by '<router_key>/<interface_name>'."
  value       = { for k, i in google_compute_router_interface.interface : k => i.id }
}

output "peer_ids" {
  description = "BGP peer IDs keyed by '<router_key>/<peer_name>'."
  value       = { for k, p in google_compute_router_peer.peer : k => p.id }
}

output "common_tags" {
  description = "Common governance tags applied as labels by this module call."
  value       = local.common_tags
}
