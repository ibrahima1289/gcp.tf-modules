# variables.tf

# ---------------------------------------------------------------------------
# Default project for all bucket resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID for bucket definitions."
  type        = string
}

# ---------------------------------------------------------------------------
# Default region / location for bucket resources.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region used as bucket location when not overridden per bucket."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance tags stamped as labels on every bucket.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with generated metadata labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud Storage bucket definitions.
# ---------------------------------------------------------------------------
variable "buckets" {
  description = "List of Cloud Storage bucket configurations to create."
  type = list(object({
    key        = string
    name       = string
    project_id = optional(string, "")
    location   = optional(string, "")

    storage_class               = optional(string, "STANDARD")
    uniform_bucket_level_access = optional(bool, true)
    force_destroy               = optional(bool, false)
    public_access_prevention    = optional(string, "enforced")
    default_event_based_hold    = optional(bool, false)
    requester_pays              = optional(bool, false)

    versioning_enabled                            = optional(bool, false)
    soft_delete_policy_retention_duration_seconds = optional(number, null)

    cors = optional(list(object({
      origin          = list(string)
      method          = list(string)
      response_header = optional(list(string), [])
      max_age_seconds = optional(number, 3600)
    })), [])

    lifecycle_rules = optional(list(object({
      action_type          = string
      action_storage_class = optional(string, "")

      condition_age                        = optional(number, null)
      condition_created_before             = optional(string, null)
      condition_with_state                 = optional(string, null)
      condition_matches_storage_class      = optional(list(string), null)
      condition_matches_prefix             = optional(list(string), null)
      condition_matches_suffix             = optional(list(string), null)
      condition_num_newer_versions         = optional(number, null)
      condition_days_since_noncurrent_time = optional(number, null)
    })), [])

    retention_policy_is_locked        = optional(bool, false)
    retention_policy_retention_period = optional(number, null)

    default_kms_key_name = optional(string, "")

    log_bucket        = optional(string, "")
    log_object_prefix = optional(string, "")

    website_main_page_suffix = optional(string, "")
    website_not_found_page   = optional(string, "")

    autoclass_enabled                = optional(bool, false)
    autoclass_terminal_storage_class = optional(string, "NEARLINE")

    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for b in var.buckets : b.key])) == length(var.buckets)
    error_message = "buckets[*].key values must be unique."
  }
}
