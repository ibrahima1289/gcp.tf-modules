# ---------------------------------------------------------------------------
# Folders: create top-level folders first.
# Parent resolution order for top-level folders:
# 1) explicit parent (organizations/<id> or folders/<id>)
# 2) default_parent (module-wide fallback parent)
# ---------------------------------------------------------------------------
resource "google_folder" "top_level" {
  for_each = local.top_level_folders_map

  display_name = each.value.display_name
  parent = (
    trimspace(each.value.parent) != ""
    ? each.value.parent
    : var.default_parent
  )
}

# ---------------------------------------------------------------------------
# Folders: create nested folders under top-level folders created above.
# Note: Terraform cannot safely resolve arbitrary recursive folder graphs in a
# single resource; this module supports one nested level per module call.
# ---------------------------------------------------------------------------
resource "google_folder" "nested" {
  for_each = local.nested_folders_map

  display_name = each.value.display_name
  parent       = google_folder.top_level[each.value.parent_folder_key].name
}

# ---------------------------------------------------------------------------
# Folder IAM members: additive grants at folder scope.
# Uses google_folder_iam_member to avoid authoritative IAM replacement.
# ---------------------------------------------------------------------------
resource "google_folder_iam_member" "member" {
  for_each = local.folder_iam_members_map

  folder = local.folder_resource_names[each.value.folder_key]
  role   = each.value.role
  member = each.value.member
}

# ---------------------------------------------------------------------------
# Folder policies: apply boolean/list OrgPolicy v2 constraints per folder.
# ---------------------------------------------------------------------------
resource "google_org_policy_policy" "policy" {
  for_each = local.folder_policies_map

  parent = local.folder_resource_names[each.value.folder_key]
  name   = "${local.folder_resource_names[each.value.folder_key]}/policies/${each.value.constraint}"

  spec {
    # Boolean policy rules.
    dynamic "rules" {
      for_each = each.value.type == "boolean" ? [each.value.enforce] : []
      content {
        enforce = rules.value
      }
    }

    # List policy rule: allow all.
    dynamic "rules" {
      for_each = each.value.type == "list" && each.value.allow_all ? [1] : []
      content {
        allow_all = "TRUE"
      }
    }

    # List policy rule: deny all.
    dynamic "rules" {
      for_each = each.value.type == "list" && each.value.deny_all ? [1] : []
      content {
        deny_all = "TRUE"
      }
    }

    # List policy rule: explicit allowed values.
    dynamic "rules" {
      for_each = (
        each.value.type == "list" &&
        !each.value.allow_all &&
        !each.value.deny_all &&
        length(each.value.allowed_values) > 0 &&
        length(each.value.denied_values) == 0
      ) ? [1] : []
      content {
        values {
          allowed_values = each.value.allowed_values
        }
      }
    }

    # List policy rule: explicit denied values.
    dynamic "rules" {
      for_each = (
        each.value.type == "list" &&
        !each.value.allow_all &&
        !each.value.deny_all &&
        length(each.value.denied_values) > 0 &&
        length(each.value.allowed_values) == 0
      ) ? [1] : []
      content {
        values {
          denied_values = each.value.denied_values
        }
      }
    }

    # List policy rule: explicit allowed and denied values.
    dynamic "rules" {
      for_each = (
        each.value.type == "list" &&
        !each.value.allow_all &&
        !each.value.deny_all &&
        length(each.value.allowed_values) > 0 &&
        length(each.value.denied_values) > 0
      ) ? [1] : []
      content {
        values {
          allowed_values = each.value.allowed_values
          denied_values  = each.value.denied_values
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Folder log sinks: centralize logs from one or more folders.
# ---------------------------------------------------------------------------
resource "google_logging_folder_sink" "sink" {
  for_each = local.folder_log_sinks_map

  folder           = replace(local.folder_resource_names[each.value.folder_key], "folders/", "")
  name             = each.value.name
  destination      = each.value.destination
  filter           = each.value.filter
  include_children = each.value.include_children
}

# ---------------------------------------------------------------------------
# Essential contacts: register contact emails at folder scope.
# ---------------------------------------------------------------------------
resource "google_essential_contacts_contact" "contact" {
  for_each = local.folder_essential_contacts_map

  parent                              = local.folder_resource_names[each.value.folder_key]
  email                               = each.value.email
  language_tag                        = each.value.language_tag
  notification_category_subscriptions = each.value.notification_categories
}

