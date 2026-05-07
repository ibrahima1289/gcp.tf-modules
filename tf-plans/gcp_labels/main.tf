# ===========================================================================
# Labels deployment plan — invokes the gcp_labels module with one or many
# label profiles defined in terraform.tfvars.
# ===========================================================================
module "labels" {
  source = "../../modules/governance/gcp_labels"

  # Project and region context.
  project_id = var.project_id
  region     = var.region

  # Base tags are merged into every computed label map.
  tags = local.extra_tags

  # Label profiles — see terraform.tfvars for examples.
  label_sets = var.label_sets
}
