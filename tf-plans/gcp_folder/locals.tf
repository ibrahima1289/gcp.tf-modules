locals {
  # ---------------------------------------------------------------------------
  # Created date metadata for traceability.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
