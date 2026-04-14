# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Creation date used for governance metadata.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common tags metadata for all resources in this module call.
  # Cloud NAT does not support labels, so these are exposed through outputs.
  # ---------------------------------------------------------------------------
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Map all NAT definitions by stable key and resolve project/region/router
  # names without using null values.
  # ---------------------------------------------------------------------------
  nats_map = {
    for n in var.nats : n.key => merge(n, {
      project_id  = trimspace(n.project_id) != "" ? n.project_id : var.project_id
      region      = trimspace(n.region) != "" ? n.region : var.region
      router_name = trimspace(n.router_name) != "" ? n.router_name : "${n.name}-router"
    })
  }

  # ---------------------------------------------------------------------------
  # NATs that need a router to be created by this module.
  # ---------------------------------------------------------------------------
  create_router_map = {
    for key, n in local.nats_map : key => n
    if n.create_router
  }

  # ---------------------------------------------------------------------------
  # NATs split by dynamic port allocation mode to keep configuration valid
  # without null assignments.
  # ---------------------------------------------------------------------------
  nats_dynamic_disabled = {
    for key, n in local.nats_map : key => n
    if !n.enable_dynamic_port_allocation
  }

  nats_dynamic_enabled = {
    for key, n in local.nats_map : key => n
    if n.enable_dynamic_port_allocation
  }
}
