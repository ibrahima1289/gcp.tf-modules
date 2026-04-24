output "global_http_lb_ips" {
  description = "Reserved global static IP addresses, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.global_http_lb_ips
}

output "global_http_lb_forwarding_rule_ips" {
  description = "Assigned IP addresses on global forwarding rules, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.global_http_lb_forwarding_rule_ips
}

output "global_http_lb_backend_service_ids" {
  description = "Self-links of global backend services, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.global_http_backend_service_ids
}

output "global_http_lb_url_map_ids" {
  description = "Self-links of global URL maps, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.global_http_url_map_ids
}

output "regional_http_lb_ips" {
  description = "Reserved regional static IP addresses, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.regional_http_lb_ips
}

output "regional_http_lb_forwarding_rule_ips" {
  description = "Assigned IP addresses on regional application LB forwarding rules, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.regional_http_lb_forwarding_rule_ips
}

output "regional_http_lb_backend_service_ids" {
  description = "Self-links of regional application LB backend services, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.regional_http_backend_service_ids
}

output "network_lb_ips" {
  description = "Reserved external static IP addresses for passthrough NLBs, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.network_lb_ips
}

output "network_lb_forwarding_rule_ips" {
  description = "Assigned IP addresses on external passthrough NLB forwarding rules, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.network_lb_forwarding_rule_ips
}

output "internal_lb_forwarding_rule_ips" {
  description = "Assigned IP addresses on internal passthrough NLB forwarding rules, keyed by lb.key."
  value       = module.gcp_cloud_load_balancer.internal_lb_forwarding_rule_ips
}

output "common_labels" {
  description = "Merged labels applied to all resources."
  value       = module.gcp_cloud_load_balancer.common_labels
}
