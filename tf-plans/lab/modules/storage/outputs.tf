output "bucket_name" {
  description = "The name of the storage bucket."
  value       = google_storage_bucket.storage-bucket.name
}

output "bucket_url" {
  description = "The base URL of the storage bucket."
  value       = google_storage_bucket.storage-bucket.url
}
