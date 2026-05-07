output "label_sets" {
  description = "Computed label map for each active label_set. Use as: labels = module.labels.label_sets[\"<key>\"]."
  value       = module.labels.label_sets
}

output "all_label_sets" {
  description = "Computed label map for all label_sets including create=false entries."
  value       = module.labels.all_label_sets
}

output "common_labels" {
  description = "Base label map shared across all resources: managed-by, created-date, and var.tags."
  value       = module.labels.common_labels
}
