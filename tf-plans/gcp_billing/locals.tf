locals {
  # ---------------------------------------------------------------------------
  # Stamp the creation date as a base label forwarded to the module.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  extra_tags = {
    created-date = local.created_date
  }
}
