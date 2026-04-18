locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())

  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # Resolve per-instance overrides; excludes create = false entries
  instances_map = {
    for i in var.instances : i.key => merge(i, {
      region = trimspace(i.region) != "" ? i.region : var.region
      labels = merge(local.common_tags, i.labels)
    })
    if i.create
  }

  # Flattened map of databases keyed "<instance_key>--<db_name>"
  databases_map = {
    for entry in flatten([
      for i in var.instances : [
        for db in i.databases : {
          composite_key = "${i.key}--${db.name}"
          instance_key  = i.key
          name          = db.name
          charset       = db.charset
          collation     = db.collation
        }
      ]
      if i.create
    ]) : entry.composite_key => entry
  }

  # Flattened map of users keyed "<instance_key>--<user_name>"
  users_map = {
    for entry in flatten([
      for i in var.instances : [
        for u in i.users : {
          composite_key = "${i.key}--${u.name}"
          instance_key  = i.key
          name          = u.name
          password      = u.password
          host          = u.host
          type          = u.type
        }
      ]
      if i.create
    ]) : entry.composite_key => entry
  }
}
