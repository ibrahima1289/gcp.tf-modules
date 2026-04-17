resource "google_cloud_identity_group" "group" {
  for_each = local.groups_map # excludes create = false entries
  parent   = local.parent     # customers/<customer_id>

  group_key {
    id = each.value.email # canonical group email
  }

  labels               = each.value.labels # at least one group-type label required
  display_name         = trimspace(each.value.display_name) != "" ? each.value.display_name : null
  description          = trimspace(each.value.description) != "" ? each.value.description : null
  initial_group_config = each.value.initial_group_config # EMPTY | WITH_INITIAL_OWNER
}

resource "google_cloud_identity_group_membership" "membership" {
  for_each = local.memberships_map # keyed "<group_key>--<member_key>"
  group    = google_cloud_identity_group.group[each.value.group_key].id

  preferred_member_key {
    id = each.value.member_email # user, SA, or nested group email
  }

  dynamic "roles" {
    for_each = each.value.roles # MEMBER always required; MANAGER/OWNER optional
    content {
      name = roles.value
    }
  }
}
