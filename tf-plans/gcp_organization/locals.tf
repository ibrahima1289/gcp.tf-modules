locals {
  # ---------------------------------------------------------------------------
  # One-time creation date stamp captured at plan time.
  # Merged into labels for all downstream resources via the module's locals.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
