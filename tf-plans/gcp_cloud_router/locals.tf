# locals.tf

locals {
  # Date tag materialized at plan time for consistent governance metadata.
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
