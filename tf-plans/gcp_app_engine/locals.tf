# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Creation date materialized at plan time for governance tag stamping.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
