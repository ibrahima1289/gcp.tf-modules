locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a governance label on all resources.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # common_labels: base label map merged into all taggable resources.
  # Billing resources (budgets, IAM) do not accept labels natively, but this
  # map is exported as an output for callers to apply to linked projects or VMs.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed-by   = "terraform"
      created-date = local.created_date
    },
    var.tags
  )
}
