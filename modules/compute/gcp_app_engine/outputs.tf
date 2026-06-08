# outputs.tf

# ---------------------------------------------------------------------------
# Step 1: App Engine application outputs.
# ---------------------------------------------------------------------------
output "application_id" {
  description = "App Engine application ID (matches the GCP project ID)."
  value       = length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].id : ""
}

output "application_name" {
  description = "Fully-qualified App Engine application name in the form apps/{project}."
  value       = length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].name : ""
}

output "application_url" {
  description = "Default HTTPS URL for the App Engine application."
  value       = length(google_app_engine_application.app) > 0 ? "https://${google_app_engine_application.app[0].default_hostname}" : ""
}

output "default_hostname" {
  description = "Default serving hostname for the application (e.g. my-project.appspot.com)."
  value       = length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].default_hostname : ""
}

output "default_bucket" {
  description = "Default GCS bucket used by App Engine for staging deployment artifacts."
  value       = length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].default_bucket : ""
}

# ---------------------------------------------------------------------------
# Step 2: Standard environment version outputs.
# ---------------------------------------------------------------------------
output "standard_version_ids" {
  description = "Standard environment version IDs keyed by service key."
  value       = { for k, v in google_app_engine_standard_app_version.standard : k => v.version_id }
}

output "standard_version_names" {
  description = "Fully-qualified standard version names (apps/{project}/services/{service}/versions/{version}) keyed by service key."
  value       = { for k, v in google_app_engine_standard_app_version.standard : k => v.name }
}

# ---------------------------------------------------------------------------
# Step 3: Flexible environment version outputs.
# ---------------------------------------------------------------------------
output "flexible_version_ids" {
  description = "Flexible environment version IDs keyed by service key."
  value       = { for k, v in google_app_engine_flexible_app_version.flexible : k => v.version_id }
}

output "flexible_version_names" {
  description = "Fully-qualified flexible version names keyed by service key."
  value       = { for k, v in google_app_engine_flexible_app_version.flexible : k => v.name }
}

# ---------------------------------------------------------------------------
# Step 4: Traffic split outputs.
# ---------------------------------------------------------------------------
output "split_traffic_ids" {
  description = "Traffic split resource IDs keyed by service key."
  value       = { for k, s in google_app_engine_service_split_traffic.split : k => s.id }
}

# ---------------------------------------------------------------------------
# Step 5: Firewall and domain outputs.
# ---------------------------------------------------------------------------
output "firewall_rule_ids" {
  description = "App Engine firewall rule IDs keyed by rule key."
  value       = { for k, r in google_app_engine_firewall_rule.rule : k => r.id }
}

output "domain_mapping_ids" {
  description = "Domain mapping resource IDs keyed by mapping key."
  value       = { for k, m in google_app_engine_domain_mapping.mapping : k => m.id }
}

output "domain_mapping_resource_records" {
  description = "DNS resource records needed to configure custom domains, keyed by mapping key. Add these records to your DNS provider."
  value       = { for k, m in google_app_engine_domain_mapping.mapping : k => m.resource_records }
}

# ---------------------------------------------------------------------------
# Step 6: Governance metadata.
# ---------------------------------------------------------------------------
output "common_tags" {
  description = "Common governance tags applied as labels in this module call."
  value       = local.common_tags
}
