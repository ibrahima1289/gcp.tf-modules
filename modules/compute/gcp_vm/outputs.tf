# ---------------------------------------------------------------------------
# Instance identity outputs — keyed by vm.key.
# ---------------------------------------------------------------------------

output "instance_ids" {
  description = "Instance resource IDs keyed by vm.key."
  value       = { for k, vm in google_compute_instance.vm : k => vm.id }
}

output "instance_names" {
  description = "Instance resource names keyed by vm.key."
  value       = { for k, vm in google_compute_instance.vm : k => vm.name }
}

output "instance_self_links" {
  description = "Self-links of all created VM instances, keyed by vm.key."
  value       = { for k, vm in google_compute_instance.vm : k => vm.self_link }
}

output "instance_zones" {
  description = "Zone of each instance, keyed by vm.key."
  value       = { for k, vm in google_compute_instance.vm : k => vm.zone }
}

# ---------------------------------------------------------------------------
# Network outputs — keyed by vm.key.
# ---------------------------------------------------------------------------

output "internal_ips" {
  description = "Internal (private) IP addresses of all instances, keyed by vm.key."
  value       = { for k, vm in google_compute_instance.vm : k => vm.network_interface[0].network_ip }
}

output "external_ips" {
  description = "External (NAT) IP addresses for instances with an access_config, keyed by vm.key. Empty string if no external IP."
  value = {
    for k, vm in google_compute_instance.vm : k =>
    length(vm.network_interface[0].access_config) > 0
    ? vm.network_interface[0].access_config[0].nat_ip
    : ""
  }
}

# ---------------------------------------------------------------------------
# Data disk outputs — keyed by "<vm_key>/<disk_name>".
# ---------------------------------------------------------------------------

output "data_disk_ids" {
  description = "Data disk resource IDs keyed by '<vm_key>/<disk_name>'."
  value       = { for k, d in google_compute_disk.data : k => d.id }
}

output "data_disk_self_links" {
  description = "Data disk self-links keyed by '<vm_key>/<disk_name>'."
  value       = { for k, d in google_compute_disk.data : k => d.self_link }
}

# ---------------------------------------------------------------------------
# Governance outputs.
# ---------------------------------------------------------------------------

output "common_labels" {
  description = "Merged governance labels applied to all resources in this module."
  value       = local.common_labels
}
