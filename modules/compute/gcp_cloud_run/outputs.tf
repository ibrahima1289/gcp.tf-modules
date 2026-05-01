# ---------------------------------------------------------------------------
# Cloud Run Service outputs
# ---------------------------------------------------------------------------

output "service_urls" {
  description = "HTTPS URLs for each Cloud Run service, keyed by service key."
  value       = { for k, s in google_cloud_run_v2_service.services : k => s.uri }
}

output "service_names" {
  description = "Cloud Run service resource names, keyed by service key."
  value       = { for k, s in google_cloud_run_v2_service.services : k => s.name }
}

output "service_ids" {
  description = "Fully qualified Cloud Run service IDs, keyed by service key."
  value       = { for k, s in google_cloud_run_v2_service.services : k => s.id }
}

output "service_latest_revisions" {
  description = "Latest ready revision names, keyed by service key."
  value       = { for k, s in google_cloud_run_v2_service.services : k => s.latest_ready_revision }
}

output "service_locations" {
  description = "GCP regions where each service is deployed, keyed by service key."
  value       = { for k, s in google_cloud_run_v2_service.services : k => s.location }
}

# ---------------------------------------------------------------------------
# Cloud Run Job outputs
# ---------------------------------------------------------------------------

output "job_names" {
  description = "Cloud Run job resource names, keyed by job key."
  value       = { for k, j in google_cloud_run_v2_job.jobs : k => j.name }
}

output "job_ids" {
  description = "Fully qualified Cloud Run job IDs, keyed by job key."
  value       = { for k, j in google_cloud_run_v2_job.jobs : k => j.id }
}

output "job_locations" {
  description = "GCP regions where each job is deployed, keyed by job key."
  value       = { for k, j in google_cloud_run_v2_job.jobs : k => j.location }
}

# ---------------------------------------------------------------------------
# Governance outputs
# ---------------------------------------------------------------------------

output "common_labels" {
  description = "Common governance labels applied to all resources."
  value       = local.common_labels
}
