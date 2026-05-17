output "instance_ids" {
  description = "Instance resource IDs keyed by vm.key."
  value       = module.gcp_vm.instance_ids
}

output "instance_names" {
  description = "Instance resource names keyed by vm.key."
  value       = module.gcp_vm.instance_names
}

output "instance_self_links" {
  description = "Self-links of all VM instances keyed by vm.key."
  value       = module.gcp_vm.instance_self_links
}

output "internal_ips" {
  description = "Internal IP addresses keyed by vm.key."
  value       = module.gcp_vm.internal_ips
}

output "external_ips" {
  description = "External IP addresses keyed by vm.key. Empty string if no external IP."
  value       = module.gcp_vm.external_ips
}

output "data_disk_ids" {
  description = "Data disk IDs keyed by '<vm_key>/<disk_name>'."
  value       = module.gcp_vm.data_disk_ids
}

output "common_labels" {
  description = "Merged governance labels applied to all resources."
  value       = module.gcp_vm.common_labels
}
