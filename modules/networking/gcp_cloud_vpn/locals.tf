locals {
  # ---------------------------------------------------------------------------
  # Creation date used for governance metadata.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged into outputs and tags for all module resources.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # HA VPN gateways map — excludes create = false entries.
  # Resolves project_id and region to the module defaults when not overridden.
  # ---------------------------------------------------------------------------
  ha_gateways_map = {
    for g in var.vpn_gateways : g.key => merge(g, {
      project_id = trimspace(g.project_id) != "" ? g.project_id : var.project_id
      region     = trimspace(g.region) != "" ? g.region : var.region
    })
    if g.create
  }

  # ---------------------------------------------------------------------------
  # Peer (external) gateways map — excludes create = false entries.
  # ---------------------------------------------------------------------------
  peer_gateways_map = {
    for p in var.peer_gateways : p.key => merge(p, {
      project_id = trimspace(p.project_id) != "" ? p.project_id : var.project_id
    })
    if p.create
  }

  # ---------------------------------------------------------------------------
  # Flat tunnel map keyed as "<gateway_key>/<tunnel_key>".
  # Flattening lets each tunnel, router interface, and BGP peer use a single
  # for_each — avoiding nested resource blocks and ensuring stable keys.
  # ---------------------------------------------------------------------------
  tunnels_flat_map = merge([
    for g in var.vpn_gateways : {
      for t in g.tunnels :
      "${g.key}/${t.key}" => merge(t, {
        gateway_key      = g.key
        project_id       = trimspace(g.project_id) != "" ? g.project_id : var.project_id
        region           = trimspace(g.region) != "" ? g.region : var.region
        peer_gateway_key = g.peer_gateway_key
      })
    }
    if g.create
  ]...)
}
