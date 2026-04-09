# Pass through all module outputs for downstream consumption.

output "org_id" {
  description = "Numeric Google Cloud Organization ID."
  value       = module.organization.org_id
}

output "org_name" {
  description = "Display name of the Google Cloud Organization."
  value       = module.organization.org_name
}

output "org_resource_name" {
  description = "Full resource name of the organization (organizations/<org_id>)."
  value       = module.organization.org_resource_name
}

output "iam_member_ids" {
  description = "Map of IAM member key to resource ID."
  value       = module.organization.iam_member_ids
}

output "org_policy_names" {
  description = "Map of org policy key to resource name."
  value       = module.organization.org_policy_names
}

output "log_sink_names" {
  description = "Map of log sink key to sink name."
  value       = module.organization.log_sink_names
}

output "log_sink_writer_identities" {
  description = "Map of log sink key to writer identity. Grant this identity write access to the sink destination."
  value       = module.organization.log_sink_writer_identities
}

output "essential_contact_ids" {
  description = "Map of essential contact key to contact resource ID."
  value       = module.organization.essential_contact_ids
}
