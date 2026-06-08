# outputs.tf

# ---------------------------------------------------------------------------
# Step 1: Application identity outputs.
# ---------------------------------------------------------------------------
output "application_id" {
  description = "App Engine application ID (matches the GCP project ID)."
  value       = module.gcp_app_engine.application_id
}

output "application_url" {
  description = "Default HTTPS URL for the App Engine application."
  value       = module.gcp_app_engine.application_url
}

output "default_hostname" {
  description = "Default hostname (e.g. my-project.appspot.com)."
  value       = module.gcp_app_engine.default_hostname
}

output "default_bucket" {
  description = "Default GCS bucket used for staging App Engine deployment artifacts."
  value       = module.gcp_app_engine.default_bucket
}

# ---------------------------------------------------------------------------
# Step 2: Version outputs.
# ---------------------------------------------------------------------------
output "standard_version_ids" {
  description = "Standard environment version IDs keyed by service key."
  value       = module.gcp_app_engine.standard_version_ids
}

output "standard_version_names" {
  description = "Fully-qualified standard version names keyed by service key."
  value       = module.gcp_app_engine.standard_version_names
}

output "flexible_version_ids" {
  description = "Flexible environment version IDs keyed by service key."
  value       = module.gcp_app_engine.flexible_version_ids
}

output "flexible_version_names" {
  description = "Fully-qualified flexible version names keyed by service key."
  value       = module.gcp_app_engine.flexible_version_names
}

# ---------------------------------------------------------------------------
# Step 3: Traffic, firewall, and domain outputs.
# ---------------------------------------------------------------------------
output "split_traffic_ids" {
  description = "Traffic split resource IDs keyed by service key."
  value       = module.gcp_app_engine.split_traffic_ids
}

output "firewall_rule_ids" {
  description = "App Engine firewall rule IDs keyed by rule key."
  value       = module.gcp_app_engine.firewall_rule_ids
}

output "domain_mapping_ids" {
  description = "Domain mapping resource IDs keyed by mapping key."
  value       = module.gcp_app_engine.domain_mapping_ids
}

output "domain_mapping_resource_records" {
  description = "DNS records to add to your DNS provider for custom domains."
  value       = module.gcp_app_engine.domain_mapping_resource_records
}

# ---------------------------------------------------------------------------
# Step 4: Governance metadata.
# ---------------------------------------------------------------------------
output "common_tags" {
  description = "Common governance tags applied in this wrapper run."
  value       = module.gcp_app_engine.common_tags
}
