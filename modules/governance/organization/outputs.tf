# Numeric Google Cloud Organization ID.
output "org_id" {
  description = "Numeric Google Cloud Organization ID."
  value       = local.resolved_org_id
}

# Display name of the organization.
output "org_name" {
  description = "Display name of the Google Cloud Organization."
  value       = var.org_domain != "" ? try(data.google_organization.org[0].name, null) : null
}

# Full resource name in organizations/<org_id> format.
output "org_resource_name" {
  description = "Full resource name of the organization (organizations/<org_id>)."
  value       = "organizations/${local.resolved_org_id}"
}

# IAM member resource IDs, keyed by user-provided key.
output "iam_member_ids" {
  description = "Map of IAM member key to resource ID (org_id/role/member)."
  value       = { for k, v in google_organization_iam_member.member : k => v.id }
}

# Org policy resource names, keyed by user-provided key.
output "org_policy_names" {
  description = "Map of org policy key to resource name."
  value       = { for k, v in google_org_policy_policy.policy : k => v.name }
}

# Log sink names, keyed by user-provided key.
output "log_sink_names" {
  description = "Map of log sink key to sink name."
  value       = { for k, v in google_logging_organization_sink.sink : k => v.name }
}

# Log sink writer identities — grant these write access to each sink destination.
output "log_sink_writer_identities" {
  description = "Map of log sink key to writer identity. Grant this service account write access to the sink destination bucket, dataset, or topic."
  value       = { for k, v in google_logging_organization_sink.sink : k => v.writer_identity }
}

# Essential contact resource IDs, keyed by user-provided key.
output "essential_contact_ids" {
  description = "Map of essential contact key to contact resource ID."
  value       = { for k, v in google_essential_contacts_contact.contact : k => v.id }
}
