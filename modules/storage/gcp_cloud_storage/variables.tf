# variables.tf

# ---------------------------------------------------------------------------
# Default project for all bucket resources. Per-bucket overrides supported.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used when a bucket item does not set project_id explicitly."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for bucket locations. Per-bucket location overrides supported.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region used as bucket location when a bucket item does not set location explicitly."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance tags merged into every bucket's labels.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with managed_by and created_date into every bucket's labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud Storage bucket definitions.
# ---------------------------------------------------------------------------
variable "buckets" {
  description = "List of Cloud Storage bucket configurations. Each item creates one bucket."
  type = list(object({
    # Unique stable key for for_each (must be unique across the list).
    key = string

    # Globally unique bucket name.
    name = string

    # Per-bucket project override. Falls back to var.project_id when empty.
    project_id = optional(string, "")

    # Bucket location (region, dual-region, or multi-region). Falls back to var.region when empty.
    location = optional(string, "")

    # Storage class: STANDARD, NEARLINE, COLDLINE, ARCHIVE.
    storage_class = optional(string, "STANDARD")

    # Enable uniform bucket-level access (disables ACLs). Recommended: true.
    uniform_bucket_level_access = optional(bool, true)

    # Force-destroy bucket even when not empty (use with caution in production).
    force_destroy = optional(bool, false)

    # Whether public access prevention is enforced. Values: enforced, inherited.
    public_access_prevention = optional(string, "enforced")

    # Enable versioning on the bucket.
    versioning_enabled = optional(bool, false)

    # Default event-based hold applied to new objects.
    default_event_based_hold = optional(bool, false)

    # Enable requester-pays model on the bucket.
    requester_pays = optional(bool, false)

    # CORS configuration list. Each entry is one CORS rule.
    cors = optional(list(object({
      origin          = list(string)
      method          = list(string)
      response_header = optional(list(string), [])
      max_age_seconds = optional(number, 3600)
    })), [])

    # Lifecycle rule list. Each entry is one lifecycle rule with action + conditions.
    lifecycle_rules = optional(list(object({
      action_type          = string               # Delete or SetStorageClass
      action_storage_class = optional(string, "") # Required for SetStorageClass action

      condition_age                        = optional(number, null)
      condition_created_before             = optional(string, null)
      condition_with_state                 = optional(string, null) # LIVE, ARCHIVED, ANY
      condition_matches_storage_class      = optional(list(string), null)
      condition_matches_prefix             = optional(list(string), null)
      condition_matches_suffix             = optional(list(string), null)
      condition_num_newer_versions         = optional(number, null)
      condition_days_since_noncurrent_time = optional(number, null)
    })), [])

    # Soft-delete policy retention duration in seconds (0 to disable).
    soft_delete_policy_retention_duration_seconds = optional(number, 604800) # 7 days default

    # Object retention mode. null = not set; "Enabled" = locked retention.
    retention_policy_is_locked        = optional(bool, false)
    retention_policy_retention_period = optional(number, null) # seconds; null = no retention policy

    # CMEK: Customer-managed encryption key resource name. Empty = Google-managed.
    default_kms_key_name = optional(string, "")

    # Logging: target bucket to receive access logs. Empty = logging disabled.
    log_bucket        = optional(string, "")
    log_object_prefix = optional(string, "")

    # Website configuration for static-site hosting.
    website_main_page_suffix = optional(string, "")
    website_not_found_page   = optional(string, "")

    # Autoclass: automatically transitions objects to the optimal storage class.
    autoclass_enabled                = optional(bool, false)
    autoclass_terminal_storage_class = optional(string, "NEARLINE") # NEARLINE or ARCHIVE

    # Additional labels merged with common tags. Must be lowercase, max 63 chars per key/value.
    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for b in var.buckets : b.key])) == length(var.buckets)
    error_message = "buckets[*].key values must be unique."
  }

  validation {
    condition     = length(distinct([for b in var.buckets : b.name])) == length(var.buckets)
    error_message = "buckets[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], b.storage_class)
    ])
    error_message = "Each buckets[*].storage_class must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : contains(["enforced", "inherited"], b.public_access_prevention)
    ])
    error_message = "Each buckets[*].public_access_prevention must be enforced or inherited."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : alltrue([
        for r in b.lifecycle_rules : contains(["Delete", "SetStorageClass"], r.action_type)
      ])
    ])
    error_message = "Each lifecycle_rules[*].action_type must be Delete or SetStorageClass."
  }

  validation {
    condition = alltrue([
      for b in var.buckets : alltrue([
        for r in b.lifecycle_rules :
        r.action_type != "SetStorageClass" || (r.action_storage_class != null && r.action_storage_class != "")
      ])
    ])
    error_message = "lifecycle_rules[*].action_storage_class is required when action_type is SetStorageClass."
  }
}
