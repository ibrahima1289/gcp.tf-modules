# outputs.tf

output "network_ids" {
  description = "Network resource IDs keyed by network key."
  value       = module.vpc.network_ids
}

output "network_names" {
  description = "Network names keyed by network key."
  value       = module.vpc.network_names
}

output "network_self_links" {
  description = "Network self-links keyed by network key. Use these values to attach subnets, VMs, and load balancers."
  value       = module.vpc.network_self_links
}

output "network_gateway_ipv4" {
  description = "Default gateway IPv4 addresses keyed by network key."
  value       = module.vpc.network_gateway_ipv4
}

output "network_projects" {
  description = "Resolved project IDs keyed by network key."
  value       = module.vpc.network_projects
}

output "common_labels" {
  description = "Common labels applied to all networks."
  value       = module.vpc.common_labels
}
