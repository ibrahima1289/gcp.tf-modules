# outputs.tf

# ---------------------------------------------------------------------------
# Step 1: Zone identity outputs passed through from the module.
# ---------------------------------------------------------------------------
output "zone_ids" {
  description = "DNS managed zone resource IDs keyed by zone key."
  value       = module.gcp_cloud_dns.zone_ids
}

output "zone_names" {
  description = "DNS managed zone resource names keyed by zone key."
  value       = module.gcp_cloud_dns.zone_names
}

output "zone_dns_names" {
  description = "DNS domain names keyed by zone key."
  value       = module.gcp_cloud_dns.zone_dns_names
}

# ---------------------------------------------------------------------------
# Step 2: Name server output — required for registrar delegation of public zones.
# ---------------------------------------------------------------------------
output "zone_name_servers" {
  description = "Authoritative name servers for each zone, keyed by zone key. Use to configure NS records at your domain registrar."
  value       = module.gcp_cloud_dns.zone_name_servers
}

output "zone_visibility" {
  description = "Zone visibility (public or private) keyed by zone key."
  value       = module.gcp_cloud_dns.zone_visibility
}

# ---------------------------------------------------------------------------
# Step 3: Record set outputs.
# ---------------------------------------------------------------------------
output "record_ids" {
  description = "DNS record IDs keyed by <zone_key>--<record_key>."
  value       = module.gcp_cloud_dns.record_ids
}

output "record_names" {
  description = "DNS record names keyed by <zone_key>--<record_key>."
  value       = module.gcp_cloud_dns.record_names
}

# ---------------------------------------------------------------------------
# Step 4: Governance metadata.
# ---------------------------------------------------------------------------
output "zone_projects" {
  description = "Resolved project IDs for each zone, keyed by zone key."
  value       = module.gcp_cloud_dns.zone_projects
}

output "common_tags" {
  description = "Common governance tags applied by this wrapper run."
  value       = module.gcp_cloud_dns.common_tags
}
