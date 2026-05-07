locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a governance label on all resources.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged into every topic and subscription resource.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )
}
