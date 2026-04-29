# ---------------------------------------------------------------------------
# Service outputs — pass-through from module
# ---------------------------------------------------------------------------
output "service_urls" {
  description = "HTTPS URLs for each Cloud Run service."
  value       = module.gcp_cloud_run.service_urls
}

output "service_names" {
  description = "Cloud Run service names."
  value       = module.gcp_cloud_run.service_names
}

output "service_ids" {
  description = "Fully qualified Cloud Run service IDs."
  value       = module.gcp_cloud_run.service_ids
}

output "service_latest_revisions" {
  description = "Latest ready revision names."
  value       = module.gcp_cloud_run.service_latest_revisions
}

output "service_locations" {
  description = "GCP regions where each service is deployed."
  value       = module.gcp_cloud_run.service_locations
}

# ---------------------------------------------------------------------------
# Job outputs — pass-through from module
# ---------------------------------------------------------------------------
output "job_names" {
  description = "Cloud Run job names."
  value       = module.gcp_cloud_run.job_names
}

output "job_ids" {
  description = "Fully qualified Cloud Run job IDs."
  value       = module.gcp_cloud_run.job_ids
}

output "job_locations" {
  description = "GCP regions where each job is deployed."
  value       = module.gcp_cloud_run.job_locations
}

output "common_labels" {
  description = "Common governance labels applied to all resources."
  value       = module.gcp_cloud_run.common_labels
}
