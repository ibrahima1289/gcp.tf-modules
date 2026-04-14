# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Creation date used for governance metadata and router labels.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common tags applied as labels to google_compute_router resources.
  # Cloud Router supports labels; interfaces and peers do not.
  # ---------------------------------------------------------------------------
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Map all router definitions by stable key and resolve project/region
  # defaults without null values.
  # ---------------------------------------------------------------------------
  routers_map = {
    for r in var.routers : r.key => merge(r, {
      project_id = trimspace(r.project_id) != "" ? r.project_id : var.project_id
      region     = trimspace(r.region) != "" ? r.region : var.region
    })
  }

  # ---------------------------------------------------------------------------
  # Flatten router interfaces into a map keyed by "<router_key>/<iface_name>".
  # Enables for_each to create all interfaces across all routers safely.
  # ---------------------------------------------------------------------------
  interfaces_map = {
    for entry in flatten([
      for rk, r in local.routers_map : [
        for iface in r.interfaces : {
          key        = "${rk}/${iface.name}"
          router_key = rk
          project_id = r.project_id
          region     = r.region
          iface      = iface
        }
      ]
    ]) : entry.key => entry
  }

  # ---------------------------------------------------------------------------
  # Flatten BGP peers into a map keyed by "<router_key>/<peer_name>".
  # Enables for_each to create all peers across all routers safely.
  # ---------------------------------------------------------------------------
  peers_map = {
    for entry in flatten([
      for rk, r in local.routers_map : [
        for peer in r.peers : {
          key        = "${rk}/${peer.name}"
          router_key = rk
          project_id = r.project_id
          region     = r.region
          peer       = peer
        }
      ]
    ]) : entry.key => entry
  }
}
