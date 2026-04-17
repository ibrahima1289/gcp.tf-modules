# outputs.tf

# ---------------------------------------------------------------------------
# Pass through all outputs from the Cloud Storage module for downstream use.
# ---------------------------------------------------------------------------

output "bucket_ids" {
  description = "Cloud Storage bucket resource IDs keyed by bucket key."
  value       = module.cloud_storage.bucket_ids
}

output "bucket_names" {
  description = "Bucket names keyed by bucket key."
  value       = module.cloud_storage.bucket_names
}

output "bucket_urls" {
  description = "gs:// URLs for each bucket, keyed by bucket key."
  value       = module.cloud_storage.bucket_urls
}

output "bucket_self_links" {
  description = "REST API self-link URIs for each bucket, keyed by bucket key."
  value       = module.cloud_storage.bucket_self_links
}

output "bucket_locations" {
  description = "Resolved bucket locations keyed by bucket key."
  value       = module.cloud_storage.bucket_locations
}

output "bucket_projects" {
  description = "Resolved project IDs for each bucket, keyed by bucket key."
  value       = module.cloud_storage.bucket_projects
}

output "bucket_storage_classes" {
  description = "Storage class per bucket, keyed by bucket key."
  value       = module.cloud_storage.bucket_storage_classes
}

output "versioning_enabled" {
  description = "Versioning state per bucket, keyed by bucket key."
  value       = module.cloud_storage.versioning_enabled
}

output "common_tags" {
  description = "Common governance tags applied to all buckets."
  value       = module.cloud_storage.common_tags
}
