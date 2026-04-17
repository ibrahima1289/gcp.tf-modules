# terraform.tfvars

# ---------------------------------------------------------------------------
# Default placement — all buckets inherit project and region unless overridden.
# ---------------------------------------------------------------------------
project_id = "main-project-492903"
region     = "us-central1"

# ---------------------------------------------------------------------------
# Common governance tags stamped as labels on every bucket.
# ---------------------------------------------------------------------------
tags = {
  owner       = "data-platform"
  environment = "production"
  team        = "platform"
}

# ---------------------------------------------------------------------------
# Bucket definitions — add or remove items to manage multiple buckets.
# ---------------------------------------------------------------------------
buckets = [
  # Data lake bucket — US multi-region, versioned, lifecycle-managed
  {
    key           = "data-lake"
    name          = "my-company-data-lake-prod"
    location      = "US"
    storage_class = "STANDARD"

    versioning_enabled          = true
    uniform_bucket_level_access = true
    public_access_prevention    = "enforced"

    soft_delete_policy_retention_duration_seconds = 0 # Disable soft-delete for this bucket - not recommended for production, but shown here for demonstration purposes.

    lifecycle_rules = [
      {
        action_type          = "SetStorageClass"
        action_storage_class = "NEARLINE"
        condition_age        = 30
      },
      {
        action_type   = "Delete"
        condition_age = 365
      }
    ]

    labels = {
      data_classification = "internal"
    }
  },
  # Backup bucket — Nearline storage, single region
  {
    key           = "backups"
    name          = "my-company-db-backups-prod"
    location      = "us-central1"
    storage_class = "NEARLINE"

    versioning_enabled          = false
    uniform_bucket_level_access = true
    public_access_prevention    = "enforced"

    soft_delete_policy_retention_duration_seconds = 0

    lifecycle_rules = [
      {
        action_type   = "Delete" # can be "Delete" or "SetStorageClass"
        condition_age = 90
      },
      {
        action_type          = "SetStorageClass"
        action_storage_class = "COLDLINE"
        condition_age        = 180
      }
    ]

    labels = {
      data_classification = "confidential"
      purpose             = "backup"
    }
  }
]
