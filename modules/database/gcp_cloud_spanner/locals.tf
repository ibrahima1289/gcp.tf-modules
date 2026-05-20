locals {
  # Step 1: Generate immutable creation metadata for governance tags.
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # Step 2: Merge generated and caller-provided common tags.
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # Step 3: Normalize all enabled instances (region/config defaults + labels).
  instances_map = {
    for i in var.instances : i.key => merge(i, {
      region = trimspace(i.region) != "" ? i.region : var.region
      config = trimspace(i.config) != "" ? i.config : "regional-${trimspace(i.region) != "" ? i.region : var.region}"
      labels = merge(local.common_tags, i.labels)
    })
    if i.create
  }

  # Step 4: Split instances by capacity model to avoid passing null arguments.
  instances_processing_units = {
    for k, i in local.instances_map : k => i
    if i.capacity_model == "PROCESSING_UNITS"
  }

  # Step 4a: Split processing-unit instances to avoid conflicting arguments.
  instances_processing_units_fixed = {
    for k, i in local.instances_processing_units : k => i
    if !i.autoscaling.enabled
  }

  instances_processing_units_autoscaled = {
    for k, i in local.instances_processing_units : k => i
    if i.autoscaling.enabled
  }

  instances_nodes = {
    for k, i in local.instances_map : k => i
    if i.capacity_model == "NODES"
  }

  # Step 5: Flatten all enabled databases and keep stable composite keys.
  databases_map = {
    for entry in flatten([
      for i in var.instances : [
        for db in i.databases : {
          composite_key            = "${i.key}--${db.key}"
          instance_key             = i.key
          create                   = db.create
          name                     = db.name
          database_dialect         = db.database_dialect
          ddl                      = db.ddl
          version_retention_period = db.version_retention_period
          deletion_protection      = db.deletion_protection
          enable_drop_protection   = db.enable_drop_protection
          kms_key_name             = db.kms_key_name
        }
      ]
      if i.create
    ]) : entry.composite_key => entry
    if try(entry.create, true)
  }
}
