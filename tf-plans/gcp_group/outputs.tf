# outputs.tf

# ---------------------------------------------------------------------------
# Pass through all outputs from the Cloud Identity Groups module.
# ---------------------------------------------------------------------------

output "group_ids" {
  description = "Cloud Identity group resource names (IDs) keyed by group key."
  value       = module.gcp_group.group_ids
}

output "group_names" {
  description = "Group display names keyed by group key."
  value       = module.gcp_group.group_names
}

output "group_emails" {
  description = "Group email addresses keyed by group key."
  value       = module.gcp_group.group_emails
}

output "membership_ids" {
  description = "Membership resource names keyed by composite key (<group_key>--<member_key>)."
  value       = module.gcp_group.membership_ids
}

output "membership_group_keys" {
  description = "Parent group key for each membership, keyed by composite key."
  value       = module.gcp_group.membership_group_keys
}

output "membership_member_emails" {
  description = "Member email for each membership, keyed by composite key."
  value       = module.gcp_group.membership_member_emails
}

output "customer_parent" {
  description = "Cloud Identity parent path used for all groups."
  value       = module.gcp_group.customer_parent
}

output "common_tags" {
  description = "Common governance metadata applied to this module call."
  value       = module.gcp_group.common_tags
}
