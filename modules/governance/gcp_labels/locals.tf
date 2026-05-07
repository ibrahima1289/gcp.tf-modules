locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a governance label on all resources.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # common_labels: base label map shared across every label_set.
  # Merges fixed governance keys (managed_by, created_date) with var.tags.
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      managed-by   = "terraform"
      created-date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # computed_labels: one merged label map per label_set key.
  # Merge order (lowest → highest precedence):
  #   common_labels → required schema fields → data_classification → extra_labels
  # Label keys follow GCP naming conventions (lowercase, hyphens allowed).
  # ---------------------------------------------------------------------------
  computed_labels = {
    for ls in var.label_sets : ls.key => merge(
      local.common_labels,
      {
        environment = ls.environment
        team        = ls.team
        application = ls.application
        cost-center = ls.cost_center
      },
      # Only include data-classification when a value is explicitly provided.
      ls.data_classification != "" ? { data-classification = ls.data_classification } : {},
      # Caller-supplied extra labels have the final say on any key.
      ls.extra_labels
    )
  }
}
