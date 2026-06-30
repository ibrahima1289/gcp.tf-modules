locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # Merge caller-supplied tags with generated governance labels
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # Active clusters map (create = true), with region and label overrides applied
  clusters_map = {
    for c in var.clusters : c.key => merge(c, {
      region = trimspace(c.region) != "" ? c.region : var.region
      labels = merge(local.common_tags, c.labels)
    })
    if c.create
  }

  # Flattened map of read-pool instances keyed "<cluster_key>--<instance_id>"
  read_pools_map = {
    for entry in flatten([
      for c in var.clusters : [
        for rp in c.read_pools : {
          composite_key      = "${c.key}--${rp.instance_id}"
          cluster_key        = c.key
          instance_id        = rp.instance_id
          cpu_count          = rp.cpu_count
          node_count         = rp.node_count
          database_flags     = rp.database_flags
          require_connectors = rp.require_connectors
          ssl_mode           = rp.ssl_mode
          enable_public_ip   = rp.enable_public_ip
          create             = rp.create
        }
      ]
      if c.create
    ]) : entry.composite_key => entry
    if entry.create
  }
}
