locals {
  # Stamped onto all resources via the module tags merge.
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
