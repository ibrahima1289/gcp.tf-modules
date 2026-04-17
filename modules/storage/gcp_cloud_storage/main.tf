# main.tf

# ---------------------------------------------------------------------------
# Step 1: Create Cloud Storage buckets from the resolved buckets map.
# Each bucket entry in var.buckets produces exactly one bucket resource.
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "bucket" {
  for_each = local.buckets_map

  # -------------------------------------------------------------------------
  # Step 2: Core bucket identity and placement.
  # -------------------------------------------------------------------------
  name          = each.value.name
  project       = each.value.project_id
  location      = each.value.location
  storage_class = each.value.storage_class

  # -------------------------------------------------------------------------
  # Step 3: Access and security controls.
  # uniform_bucket_level_access disables object-level ACLs — recommended on.
  # public_access_prevention blocks public exposure when set to "enforced".
  # -------------------------------------------------------------------------
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  public_access_prevention    = each.value.public_access_prevention
  force_destroy               = each.value.force_destroy
  default_event_based_hold    = each.value.default_event_based_hold
  requester_pays              = each.value.requester_pays

  # -------------------------------------------------------------------------
  # Step 4: Resource labels from merged common tags and per-bucket overrides.
  # -------------------------------------------------------------------------
  labels = each.value.labels

  # -------------------------------------------------------------------------
  # Step 5: Versioning block. Enables object version history.
  # -------------------------------------------------------------------------
  versioning {
    enabled = each.value.versioning_enabled
  }

  # -------------------------------------------------------------------------
  # Step 6: Soft-delete policy. Controls how long deleted objects are retained.
  # Set retention_duration_seconds = 0 to disable soft-delete entirely.
  # -------------------------------------------------------------------------
  soft_delete_policy {
    retention_duration_seconds = each.value.soft_delete_policy_retention_duration_seconds
  }

  # -------------------------------------------------------------------------
  # Step 7: Autoclass. When enabled, automatically moves objects to the most
  # cost-effective storage class based on access patterns.
  # -------------------------------------------------------------------------
  dynamic "autoclass" {
    for_each = each.value.autoclass_enabled ? [1] : []
    content {
      enabled                = true
      terminal_storage_class = each.value.autoclass_terminal_storage_class
    }
  }

  # -------------------------------------------------------------------------
  # Step 8: Customer-managed encryption key (CMEK). Only applied when
  # default_kms_key_name is non-empty.
  # -------------------------------------------------------------------------
  dynamic "encryption" {
    for_each = trimspace(each.value.default_kms_key_name) != "" ? [1] : []
    content {
      default_kms_key_name = each.value.default_kms_key_name
    }
  }

  # -------------------------------------------------------------------------
  # Step 9: Lifecycle rules. Each rule defines an action (Delete or
  # SetStorageClass) and the conditions that trigger it.
  # -------------------------------------------------------------------------
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lifecycle_rule.value.action_type == "SetStorageClass" ? lifecycle_rule.value.action_storage_class : null
      }
      condition {
        age                        = lifecycle_rule.value.condition_age
        created_before             = lifecycle_rule.value.condition_created_before
        with_state                 = lifecycle_rule.value.condition_with_state
        matches_storage_class      = lifecycle_rule.value.condition_matches_storage_class
        matches_prefix             = lifecycle_rule.value.condition_matches_prefix
        matches_suffix             = lifecycle_rule.value.condition_matches_suffix
        num_newer_versions         = lifecycle_rule.value.condition_num_newer_versions
        days_since_noncurrent_time = lifecycle_rule.value.condition_days_since_noncurrent_time
      }
    }
  }

  # -------------------------------------------------------------------------
  # Step 10: CORS configuration. Only rendered for buckets that define rules.
  # -------------------------------------------------------------------------
  dynamic "cors" {
    for_each = each.value.cors
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # -------------------------------------------------------------------------
  # Step 11: Access logging. Sends GCS access logs to the target log_bucket.
  # Only applied when log_bucket is non-empty.
  # -------------------------------------------------------------------------
  dynamic "logging" {
    for_each = trimspace(each.value.log_bucket) != "" ? [1] : []
    content {
      log_bucket        = each.value.log_bucket
      log_object_prefix = trimspace(each.value.log_object_prefix) != "" ? each.value.log_object_prefix : each.value.name
    }
  }

  # -------------------------------------------------------------------------
  # Step 12: Static website hosting configuration. Only applied when
  # website_main_page_suffix is non-empty.
  # -------------------------------------------------------------------------
  dynamic "website" {
    for_each = trimspace(each.value.website_main_page_suffix) != "" ? [1] : []
    content {
      main_page_suffix = each.value.website_main_page_suffix
      not_found_page   = trimspace(each.value.website_not_found_page) != "" ? each.value.website_not_found_page : null
    }
  }

  # -------------------------------------------------------------------------
  # Step 13: Retention policy. Prevents object deletion or replacement until
  # the retention period elapses. Only applied when retention_period is set.
  # Set retention_policy_is_locked = true to make the policy permanent.
  # -------------------------------------------------------------------------
  dynamic "retention_policy" {
    for_each = each.value.retention_policy_retention_period != null ? [1] : []
    content {
      is_locked        = each.value.retention_policy_is_locked
      retention_period = each.value.retention_policy_retention_period
    }
  }
}
