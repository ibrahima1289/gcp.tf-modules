module "gcp_group" {
  source = "../../modules/security/gcp_group"

  customer_id = var.customer_id

  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  groups = var.groups
}
