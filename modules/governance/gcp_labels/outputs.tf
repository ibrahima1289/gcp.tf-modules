output "label_sets" {
  description = "Computed label map for each active (create=true) label_set key. Use this map to apply labels to GCP resources: labels = module.labels.label_sets[\"<key>\"]."
  value = {
    for k in keys(terraform_data.label_sets) : k => local.computed_labels[k]
  }
}

output "all_label_sets" {
  description = "Computed label map for ALL label_set entries including those with create=false. Useful for referencing labels before committing to state tracking."
  value       = local.computed_labels
}

output "common_labels" {
  description = "Base label map shared across all resources: managed-by, created-date, and any var.tags entries."
  value       = local.common_labels
}
