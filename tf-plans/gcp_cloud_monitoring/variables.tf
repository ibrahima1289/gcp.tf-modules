variable "project_id" {
  description = "GCP project ID for all Cloud Monitoring resources."
  type        = string
}

variable "region" {
  description = "GCP region used by the provider. Cloud Monitoring is global but the provider requires a region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with generated metadata into all resources."
  type        = map(string)
  default     = {}
}

variable "notification_channels" {
  description = "List of notification channel configurations."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    display_name = string
    type         = string
    labels       = optional(map(string), {})
    sensitive_labels = optional(object({
      auth_token  = optional(string, "")
      password    = optional(string, "")
      service_key = optional(string, "")
    }), null)
    enabled     = optional(bool, true)
    user_labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for c in var.notification_channels : c.key])) == length(var.notification_channels)
    error_message = "notification_channels[*].key values must be unique."
  }
}

variable "alert_policies" {
  description = "List of alert policy configurations."
  type = list(object({
    key                       = string
    create                    = optional(bool, true)
    display_name              = string
    combiner                  = optional(string, "OR")
    enabled                   = optional(bool, true)
    notification_channel_keys = optional(list(string), [])
    documentation_content     = optional(string, "")

    conditions = list(object({
      display_name = string

      condition_threshold = optional(object({
        filter          = string
        duration        = optional(string, "60s")
        comparison      = optional(string, "COMPARISON_GT")
        threshold_value = optional(number, 0)
        aggregations = optional(list(object({
          alignment_period     = optional(string, "60s")
          per_series_aligner   = optional(string, "ALIGN_MEAN")
          cross_series_reducer = optional(string, "")
          group_by_fields      = optional(list(string), [])
        })), [])
      }), null)

      condition_absent = optional(object({
        filter   = string
        duration = optional(string, "300s")
        aggregations = optional(list(object({
          alignment_period     = optional(string, "60s")
          per_series_aligner   = optional(string, "ALIGN_MEAN")
          cross_series_reducer = optional(string, "")
          group_by_fields      = optional(list(string), [])
        })), [])
      }), null)

      condition_matched_log = optional(object({
        filter           = string
        label_extractors = optional(map(string), {})
      }), null)
    }))

    alert_strategy = optional(object({
      auto_close = optional(string, "604800s")
      notification_rate_limit = optional(object({
        period = optional(string, "3600s")
      }), null)
    }), null)

    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.alert_policies : p.key])) == length(var.alert_policies)
    error_message = "alert_policies[*].key values must be unique."
  }
}

variable "uptime_checks" {
  description = "List of uptime check configurations."
  type = list(object({
    key              = string
    create           = optional(bool, true)
    display_name     = string
    timeout          = optional(string, "10s")
    period           = optional(string, "60s")
    checker_type     = optional(string, "STATIC_IP_CHECKERS")
    selected_regions = optional(list(string), [])

    http_check = optional(object({
      path           = optional(string, "/")
      port           = optional(number, 443)
      use_ssl        = optional(bool, true)
      validate_ssl   = optional(bool, true)
      request_method = optional(string, "GET")
      headers        = optional(map(string), {})
      accepted_response_status_codes = optional(list(object({
        status_class = optional(string, "STATUS_CLASS_2XX")
        status_value = optional(number, 0)
      })), [])
    }), null)

    tcp_check = optional(object({
      port = number
    }), null)

    monitored_resource = optional(object({
      type   = string
      labels = map(string)
    }), null)

    resource_group = optional(object({
      group_id      = optional(string, "")
      resource_type = optional(string, "INSTANCE")
    }), null)

    content_matchers = optional(list(object({
      content = string
      matcher = optional(string, "CONTAINS_STRING")
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for u in var.uptime_checks : u.key])) == length(var.uptime_checks)
    error_message = "uptime_checks[*].key values must be unique."
  }
}

variable "dashboards" {
  description = "List of monitoring dashboard configurations."
  type = list(object({
    key            = string
    create         = optional(bool, true)
    dashboard_json = string
  }))
  default = []

  validation {
    condition     = length(distinct([for d in var.dashboards : d.key])) == length(var.dashboards)
    error_message = "dashboards[*].key values must be unique."
  }
}
