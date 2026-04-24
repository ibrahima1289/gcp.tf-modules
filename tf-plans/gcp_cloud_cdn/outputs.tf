output "backend_bucket_ids" {
  description = "Backend bucket resource IDs, keyed by entry key."
  value       = module.gcp_cloud_cdn.backend_bucket_ids
}

output "backend_bucket_self_links" {
  description = "Backend bucket self-links for use in URL maps, keyed by entry key."
  value       = module.gcp_cloud_cdn.backend_bucket_self_links
}

output "backend_service_ids" {
  description = "Backend service resource IDs, keyed by entry key."
  value       = module.gcp_cloud_cdn.backend_service_ids
}

output "backend_service_self_links" {
  description = "Backend service self-links for use in URL maps, keyed by entry key."
  value       = module.gcp_cloud_cdn.backend_service_self_links
}

output "health_check_ids" {
  description = "Health check resource IDs for backend service CDN entries, keyed by entry key."
  value       = module.gcp_cloud_cdn.health_check_ids
}

output "common_labels" {
  description = "Merged governance labels applied to all resources."
  value       = module.gcp_cloud_cdn.common_labels
}
