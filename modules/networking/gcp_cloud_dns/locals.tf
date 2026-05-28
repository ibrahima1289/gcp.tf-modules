# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Step 1: Creation date for governance metadata stamped at plan time.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Step 2: Common tags merged into every zone's label map.
  # ---------------------------------------------------------------------------
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Step 3: Build the primary zone map.
  # Resolves per-zone project override and merges common tags into labels.
  # Only zones with create = true are included.
  # ---------------------------------------------------------------------------
  zones_map = {
    for z in var.zones : z.key => merge(z, {
      project_id = trimspace(z.project_id) != "" ? z.project_id : var.project_id
      labels     = merge(local.common_tags, z.labels)
    })
    if z.create
  }

  # ---------------------------------------------------------------------------
  # Step 4: Flatten all records across enabled zones into a single map.
  # Composite key format: "<zone_key>--<record_key>" ensures uniqueness and
  # stable Terraform state when zones or records are reordered.
  # ---------------------------------------------------------------------------
  records_all = {
    for entry in flatten([
      for z in var.zones : [
        for r in z.records : {
          composite_key  = "${z.key}--${r.key}"
          zone_key       = z.key
          project_id     = trimspace(z.project_id) != "" ? z.project_id : var.project_id
          record_name    = r.name
          type           = r.type
          ttl            = r.ttl
          create         = r.create
          rrdatas        = r.rrdatas
          routing_policy = r.routing_policy
        }
      ]
      if z.create
    ]) : entry.composite_key => entry
    if entry.create
  }

  # ---------------------------------------------------------------------------
  # Step 5: Split records by routing mode to prevent argument conflicts.
  # Simple records use rrdatas; routed records use routing_policy block only.
  # ---------------------------------------------------------------------------
  records_simple = {
    for k, r in local.records_all : k => r
    if !r.routing_policy.enabled
  }

  records_routed = {
    for k, r in local.records_all : k => r
    if r.routing_policy.enabled
  }
}
