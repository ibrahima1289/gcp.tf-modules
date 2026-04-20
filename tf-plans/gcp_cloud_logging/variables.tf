variable "project_id" {
  description = "GCP project ID where all Cloud Logging resources are created."
  type        = string
}

variable "region" {
  description = "Default GCP region used by the provider."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels applied to all labelable resources."
  type        = map(string)
  default     = {}
}

variable "log_buckets" {
  description = "List of custom log bucket configurations."
  type = list(object({
    key              = string
    create           = optional(bool, true)
    bucket_id        = string
    location         = optional(string, "global")
    retention_days   = optional(number, 30)
    description      = optional(string, "")
    locked           = optional(bool, false)
    enable_analytics = optional(bool, false)
    kms_key_name     = optional(string, "")
  }))
  default = []
}

variable "log_sinks" {
  description = "List of log sink configurations."
  type = list(object({
    key                    = string
    create                 = optional(bool, true)
    name                   = string
    destination            = string
    filter                 = optional(string, "")
    description            = optional(string, "")
    unique_writer_identity = optional(bool, true)
    bigquery_options = optional(object({
      use_partitioned_tables = optional(bool, true)
    }), null)
    exclusions = optional(list(object({
      name        = string
      description = optional(string, "")
      filter      = string
      disabled    = optional(bool, false)
    })), [])
  }))
  default = []
}

variable "log_exclusions" {
  description = "List of project-wide log exclusion rules."
  type = list(object({
    key         = string
    create      = optional(bool, true)
    name        = string
    description = optional(string, "")
    filter      = string
    disabled    = optional(bool, false)
  }))
  default = []
}

variable "log_metrics" {
  description = "List of log-based metric configurations."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    name         = string
    description  = optional(string, "")
    filter       = string
    metric_kind  = optional(string, "DELTA")
    value_type   = optional(string, "INT64")
    unit         = optional(string, "1")
    display_name = optional(string, "")
    labels = optional(list(object({
      key         = string
      value_type  = optional(string, "STRING")
      description = optional(string, "")
    })), [])
    label_extractors = optional(map(string), {})
    value_extractor  = optional(string, "")
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
}
