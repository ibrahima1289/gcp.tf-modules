locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a governance label on every resource.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged into outputs and passed to callers for consistent
  # governance tagging across all resources in this module.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )
}
