variable "project_id" {
  description = "GCP project ID where all Cloud Logging resources are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "region" {
  description = "Default GCP region used by the provider. Log buckets may use 'global' or a specific region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with managed_by and created_date into all labelable resources."
  type        = map(string)
  default     = {}
}

# ── Log Buckets ─────────────────────────────────────────────────────────────────

variable "log_buckets" {
  description = "List of custom log bucket configurations. Each entry creates one logging bucket with configurable retention and optional Log Analytics."
  type = list(object({
    key              = string
    create           = optional(bool, true)
    bucket_id        = string                     # unique ID within the project (e.g. "security-logs")
    location         = optional(string, "global") # global | us-central1 | etc.
    retention_days   = optional(number, 30)       # 1–3650 days
    description      = optional(string, "")
    locked           = optional(bool, false) # prevent deletion or retention reduction
    enable_analytics = optional(bool, false) # enable Log Analytics (BigQuery-backed SQL)
    kms_key_name     = optional(string, "")  # Cloud KMS key for CMEK; empty = Google-managed
  }))
  default = []

  validation {
    condition     = length(distinct([for b in var.log_buckets : b.key])) == length(var.log_buckets)
    error_message = "log_buckets[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for b in var.log_buckets : b.retention_days >= 1 && b.retention_days <= 3650
    ])
    error_message = "log_buckets[*].retention_days must be between 1 and 3650."
  }
}

# ── Log Sinks ───────────────────────────────────────────────────────────────────

variable "log_sinks" {
  description = "List of log sink configurations. Each entry routes filtered log entries to an external destination (GCS, BigQuery, Pub/Sub, or log bucket)."
  type = list(object({
    key                    = string
    create                 = optional(bool, true)
    name                   = string
    destination            = string               # full resource URI of the export destination
    filter                 = optional(string, "") # empty string exports all logs
    description            = optional(string, "")
    unique_writer_identity = optional(bool, true) # true = per-sink SA; false = shared logging SA

    # BigQuery-only: partition exported tables by log timestamp
    bigquery_options = optional(object({
      use_partitioned_tables = optional(bool, true)
    }), null)

    # Per-sink exclusions: drop matching entries before they reach the destination
    exclusions = optional(list(object({
      name        = string
      description = optional(string, "")
      filter      = string
      disabled    = optional(bool, false)
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for s in var.log_sinks : s.key])) == length(var.log_sinks)
    error_message = "log_sinks[*].key values must be unique."
  }
}

# ── Log Exclusions ──────────────────────────────────────────────────────────────

variable "log_exclusions" {
  description = "List of project-wide log exclusion rules. Each entry drops matching log entries before ingestion, reducing cost."
  type = list(object({
    key         = string
    create      = optional(bool, true)
    name        = string
    description = optional(string, "")
    filter      = string                # Cloud Logging filter expression selecting entries to drop
    disabled    = optional(bool, false) # set true to pause without deleting
  }))
  default = []

  validation {
    condition     = length(distinct([for e in var.log_exclusions : e.key])) == length(var.log_exclusions)
    error_message = "log_exclusions[*].key values must be unique."
  }
}

# ── Log-Based Metrics ───────────────────────────────────────────────────────────

variable "log_metrics" {
  description = "List of log-based metric configurations. Each entry creates a Cloud Monitoring metric derived from matching log entries."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    name         = string
    description  = optional(string, "")
    filter       = string                    # Cloud Logging filter selecting entries to measure
    metric_kind  = optional(string, "DELTA") # DELTA | GAUGE | CUMULATIVE
    value_type   = optional(string, "INT64") # INT64 | DISTRIBUTION | BOOL | DOUBLE | STRING
    unit         = optional(string, "1")     # "1" for counts; "ms" for latency; "By" for bytes
    display_name = optional(string, "")

    # Metric label definitions; enables slicing by log entry fields
    labels = optional(list(object({
      key         = string
      value_type  = optional(string, "STRING") # STRING | BOOL | INT64
      description = optional(string, "")
    })), [])

    # Maps metric label keys to log entry field extractor expressions (EXTRACT() / REGEXP_EXTRACT())
    label_extractors = optional(map(string), {})

    # For DISTRIBUTION metrics: extract the numeric value to measure from each log entry
    value_extractor = optional(string, "")

    # Histogram buckets — only valid when value_type = DISTRIBUTION
    bucket_options = optional(object({
      linear_buckets = optional(object({
        num_finite_buckets = number
        width              = number
        offset             = number
      }), null)
      exponential_buckets = optional(object({
        num_finite_buckets = number
        growth_factor      = number
        scale              = number
      }), null)
      explicit_buckets = optional(object({
        bounds = list(number)
      }), null)
    }), null)
  }))
  default = []

  validation {
    condition     = length(distinct([for m in var.log_metrics : m.key])) == length(var.log_metrics)
    error_message = "log_metrics[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for m in var.log_metrics : contains(["DELTA", "GAUGE", "CUMULATIVE"], m.metric_kind)
    ])
    error_message = "log_metrics[*].metric_kind must be DELTA, GAUGE, or CUMULATIVE."
  }

  validation {
    condition = alltrue([
      for m in var.log_metrics : contains(["INT64", "DISTRIBUTION", "BOOL", "DOUBLE", "STRING"], m.value_type)
    ])
    error_message = "log_metrics[*].value_type must be INT64, DISTRIBUTION, BOOL, DOUBLE, or STRING."
  }
}
