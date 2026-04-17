locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  parent = "customers/${var.customer_id}" # Cloud Identity parent path

  groups_map = { # excludes create = false entries
    for g in var.groups : g.key => g
    if g.create
  }

  memberships_map = { # keyed "<group_key>--<member_key>"; excludes create = false
    for entry in flatten([
      for g in var.groups : [
        for m in g.members : {
          composite_key = "${g.key}--${m.key}"
          group_key     = g.key
          member_email  = m.member_email
          roles         = m.roles
          create        = m.create
        }
      ]
      if g.create
    ]) : entry.composite_key => entry
    if entry.create
  }
}
