# ---------------------------------------------------------------------------
# Backend Bucket CDN outputs
# ---------------------------------------------------------------------------

output "backend_bucket_ids" {
  description = "Self-links of backend bucket resources, keyed by entry key."
  value       = { for k, b in google_compute_backend_bucket.cdn : k => b.id }
}

output "backend_bucket_self_links" {
  description = "Self-links of backend bucket resources (usable in URL maps), keyed by entry key."
  value       = { for k, b in google_compute_backend_bucket.cdn : k => b.self_link }
}

# ---------------------------------------------------------------------------
# Backend Service CDN outputs
# ---------------------------------------------------------------------------

output "backend_service_ids" {
  description = "Self-links of backend service resources, keyed by entry key."
  value       = { for k, s in google_compute_backend_service.cdn : k => s.id }
}

output "backend_service_self_links" {
  description = "Self-links of backend service resources (usable in URL maps), keyed by entry key."
  value       = { for k, s in google_compute_backend_service.cdn : k => s.self_link }
}

output "health_check_ids" {
  description = "Health check resource IDs for backend service CDN entries, keyed by entry key."
  value       = { for k, h in google_compute_health_check.backend_service_cdn : k => h.id }
}

# ---------------------------------------------------------------------------
# Governance metadata
# ---------------------------------------------------------------------------

output "common_labels" {
  description = "Merged governance labels applied to all resources (managed_by, created_date, + caller tags)."
  value       = local.common_labels
}
