resource "google_storage_bucket" "storage-bucket" {
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
