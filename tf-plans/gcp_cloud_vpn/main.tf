# Pass all configuration to the Cloud VPN module.
# Cloud Router is not created here — provision it separately using the Cloud Router module.
module "gcp_cloud_vpn" {
  source        = "../../modules/networking/gcp_cloud_vpn"
  project_id    = var.project_id
  region        = var.region
  peer_gateways = var.peer_gateways # external peer gateway definitions (on-prem / AWS / Azure)
  vpn_gateways  = var.vpn_gateways  # HA VPN gateways with tunnels and BGP sessions

  # Merge caller-supplied tags with generated metadata
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )
}
