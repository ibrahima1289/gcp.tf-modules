# outputs.tf

output "network_ids" {
  description = "Network resource IDs keyed by network key."
  value       = { for k, n in google_compute_network.network : k => n.id }
}

output "network_names" {
  description = "Network names keyed by network key."
  value       = { for k, n in google_compute_network.network : k => n.name }
}

output "network_self_links" {
  description = "Network self-links keyed by network key. Used when attaching subnets, VMs, or load balancers."
  value       = { for k, n in google_compute_network.network : k => n.self_link }
}

output "network_gateway_ipv4" {
  description = "Default gateway IPv4 address for each network, keyed by network key."
  value       = { for k, n in google_compute_network.network : k => n.gateway_ipv4 }
}

output "network_projects" {
  description = "Resolved project IDs for each network, keyed by network key."
  value       = { for k, n in local.resolved_networks_map : k => n.project_id }
}

output "common_labels" {
  description = "Common labels applied to all networks in this module call."
  value       = local.common_labels
}
