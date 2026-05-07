# ===========================================================================
# Step 1: Label-set trackers
# One terraform_data resource is created per active label_set entry.
# Because labels are metadata arguments (not standalone GCP resources),
# terraform_data acts as a state sentinel: replacing when any computed label
# value changes makes drift visible in `terraform plan` without touching the
# target resources themselves.
# ===========================================================================
resource "terraform_data" "label_sets" {
  for_each = { for ls in var.label_sets : ls.key => ls if ls.create }

  # Replacing this value forces a plan diff whenever any label in the set
  # changes — giving operators a clear signal to re-apply labels downstream.
  triggers_replace = jsonencode(local.computed_labels[each.key])
}
