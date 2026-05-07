locals {
  # ---------------------------------------------------------------------------
  # Creation date forwarded as an extra base tag into the module.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  extra_tags = merge(
    {
      created-date = local.created_date
    },
    var.tags
  )
}
