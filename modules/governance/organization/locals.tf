locals {
  # ---------------------------------------------------------------------------
  # Created date stamp: captured once at plan time and stored as a label value.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels for reference.
  # Most organization-level GCP resources do not support resource labels
  # natively; these are available for use in outputs or descriptions.
  # ---------------------------------------------------------------------------
  common_labels = merge(var.labels, {
    created_date = local.created_date
    managed_by   = "terraform"
  })

  # ---------------------------------------------------------------------------
  # Convert input lists to maps for stable for_each identity.
  # Keyed by the user-provided key field on each object.
  # ---------------------------------------------------------------------------

  # IAM member grants — one entry per role+member combination.
  iam_members_map = {
    for m in var.iam_members : m.key => m
  }

  # Org policy constraints — one entry per constraint.
  org_policies_map = {
    for p in var.org_policies : p.key => p
  }

  # Log sinks — one entry per sink destination.
  log_sinks_map = {
    for s in var.log_sinks : s.key => s
  }

  # Essential contacts — one entry per contact email.
  essential_contacts_map = {
    for c in var.essential_contacts : c.key => c
  }
}
