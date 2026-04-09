# ---------------------------------------------------------------------------
# Data: look up the existing Google Cloud Organization by domain or numeric ID.
# Organizations cannot be created via Terraform — they are provisioned outside
# this automation via Google Workspace or Cloud Identity.
# ---------------------------------------------------------------------------
data "google_organization" "org" {
  # Lookup is only required when org_domain is used.
  count  = var.org_id == "" ? 1 : 0
  domain = var.org_domain
}

locals {
  # Resolve org_id from direct input when provided, otherwise from domain lookup.
  resolved_org_id = var.org_id != "" ? var.org_id : data.google_organization.org[0].org_id
}

# ---------------------------------------------------------------------------
# IAM members: additive grants at the organization level.
# Uses google_organization_iam_member (additive) rather than the authoritative
# google_organization_iam_binding to avoid wiping unmanaged principals on apply.
# ---------------------------------------------------------------------------
resource "google_organization_iam_member" "member" {
  for_each = local.iam_members_map

  org_id = local.resolved_org_id
  role   = each.value.role
  member = each.value.member
}

# ---------------------------------------------------------------------------
# Org policies: apply boolean or list constraint policies via OrgPolicy v2 API.
# Boolean: enforce or un-enforce a constraint.
# List: allow all, deny all, or specify explicit allowed/denied values.
# ---------------------------------------------------------------------------
resource "google_org_policy_policy" "policy" {
  for_each = local.org_policies_map

  # Resource name format required by the OrgPolicy v2 API.
  name   = "organizations/${local.resolved_org_id}/policies/${each.value.constraint}"
  parent = "organizations/${local.resolved_org_id}"

  spec {
    # Boolean policy: enforce or un-enforce the named constraint.
    dynamic "rules" {
      for_each = each.value.type == "boolean" ? [each.value.enforce] : []
      content {
        enforce = rules.value
      }
    }

    # List policy — allow all values.
    dynamic "rules" {
      for_each = each.value.type == "list" && each.value.allow_all ? ["TRUE"] : []
      content {
        allow_all = rules.value
      }
    }

    # List policy — deny all values.
    dynamic "rules" {
      for_each = each.value.type == "list" && each.value.deny_all ? ["TRUE"] : []
      content {
        deny_all = rules.value
      }
    }

    # List policy — explicit allowed/denied value sets.
    dynamic "rules" {
      for_each = (
        each.value.type == "list" &&
        !each.value.allow_all &&
        !each.value.deny_all &&
        length(concat(each.value.allowed_values, each.value.denied_values)) > 0
      ) ? [1] : []
      content {
        values {
          allowed_values = length(each.value.allowed_values) > 0 ? each.value.allowed_values : null
          denied_values  = length(each.value.denied_values) > 0 ? each.value.denied_values : null
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Log sinks: route organization-wide logs to a central destination (GCS,
# BigQuery, Pub/Sub, or a Cloud Logging bucket).
# Set include_children = true to aggregate logs from all child projects.
# ---------------------------------------------------------------------------
resource "google_logging_organization_sink" "sink" {
  for_each = local.log_sinks_map

  name             = each.value.name
  org_id           = local.resolved_org_id
  destination      = each.value.destination
  filter           = each.value.filter
  include_children = each.value.include_children
}

# ---------------------------------------------------------------------------
# Essential contacts: register email recipients for organization-level alerts.
# Covers notification categories: BILLING, LEGAL, SECURITY, TECHNICAL, etc.
# ---------------------------------------------------------------------------
resource "google_essential_contacts_contact" "contact" {
  for_each = local.essential_contacts_map

  parent                              = "organizations/${local.resolved_org_id}"
  email                               = each.value.email
  language_tag                        = each.value.language_tag
  notification_category_subscriptions = each.value.notification_categories
}
