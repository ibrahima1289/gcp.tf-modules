# Pass-through output: subnet self links.
output "subnet_self_links" {
  description = "Map of subnet key to subnet self link."
  value       = module.subnet.subnet_self_links
}

# Pass-through output: subnet names.
output "subnet_names" {
  description = "Map of subnet key to subnet name."
  value       = module.subnet.subnet_names
}

# Pass-through output: subnet regions.
output "subnet_regions" {
  description = "Map of subnet key to effective region."
  value       = module.subnet.subnet_regions
}

# Pass-through output: subnet CIDR ranges.
output "subnet_cidr_ranges" {
  description = "Map of subnet key to primary CIDR range."
  value       = module.subnet.subnet_cidr_ranges
}

# Pass-through output: subnet gateway addresses.
output "subnet_gateway_addresses" {
  description = "Map of subnet key to gateway address."
  value       = module.subnet.subnet_gateway_addresses
}

# Pass-through output: private Google access setting.
output "subnet_private_google_access" {
  description = "Map of subnet key to private Google access status."
  value       = module.subnet.subnet_private_google_access
}

# Pass-through output: common labels.
output "common_labels" {
  description = "Common labels map merged with created_date and managed_by."
  value       = module.subnet.common_labels
}
