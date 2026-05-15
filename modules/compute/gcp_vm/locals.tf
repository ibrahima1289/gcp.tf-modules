locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a governance label on all VM resources.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged onto every VM instance.
  # Caller-supplied tags are merged with managed_by and created_date.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )
}
