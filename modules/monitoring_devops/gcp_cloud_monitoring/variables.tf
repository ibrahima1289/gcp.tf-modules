variable "project_id" {
  description = "GCP project ID where all Cloud Monitoring resources are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "region" {
  description = "Default GCP region used by the provider. Cloud Monitoring resources are global but a region is required by the provider block."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with managed_by and created_date into all labelable resources."
  type        = map(string)
  default     = {}
}

# ── Notification Channels ──────────────────────────────────────────────────────

variable "notification_channels" {
  description = "List of notification channel configurations. Each entry creates one delivery endpoint used by alert policies."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    display_name = string
    type         = string # email | slack | pagerduty | pubsub | webhook_tokenauth | sms | google_chat

    # Type-specific non-sensitive config (e.g. email_address for email; channel_name for Slack; topic for pubsub)
    labels = optional(map(string), {})

    # Sensitive credentials stored separately from labels
    sensitive_labels = optional(object({
      auth_token  = optional(string, "") # Slack or webhook auth token
      password    = optional(string, "") # basic auth password
      service_key = optional(string, "") # PagerDuty service/integration key
    }), null)

    enabled     = optional(bool, true)
    user_labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for c in var.notification_channels : c.key])) == length(var.notification_channels)
    error_message = "notification_channels[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for c in var.notification_channels : contains(
        ["email", "slack", "pagerduty", "pubsub", "webhook_tokenauth", "sms", "google_chat", "mobile"],
        c.type
      )
    ])
    error_message = "notification_channels[*].type must be one of: email, slack, pagerduty, pubsub, webhook_tokenauth, sms, google_chat, mobile."
  }
}

# ── Alert Policies ─────────────────────────────────────────────────────────────

variable "alert_policies" {
  description = "List of alert policy configurations. Each entry creates one policy with one or more conditions and optional notification channels."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    display_name = string
    combiner     = optional(string, "OR") # OR | AND | AND_WITH_MATCHING_RESOURCE
    enabled      = optional(bool, true)

    # Keys referencing notification_channels[] entries created by this module
    notification_channel_keys = optional(list(string), [])

    # Markdown run-book text shown in the alert detail pane and notification messages
    documentation_content = optional(string, "")

    conditions = list(object({
      display_name = string

      # Threshold condition: fires when a metric value crosses a numeric boundary
      condition_threshold = optional(object({
        filter          = string                            # MQL/resource filter selecting the time series
        duration        = optional(string, "60s")           # violation must persist this long before firing
        comparison      = optional(string, "COMPARISON_GT") # COMPARISON_GT | COMPARISON_LT | COMPARISON_GE | COMPARISON_LE | COMPARISON_EQ | COMPARISON_NE
        threshold_value = optional(number, 0)

        aggregations = optional(list(object({
          alignment_period     = optional(string, "60s")
          per_series_aligner   = optional(string, "ALIGN_MEAN") # ALIGN_MEAN | ALIGN_MAX | ALIGN_MIN | ALIGN_SUM | ALIGN_COUNT | ALIGN_RATE | ALIGN_NONE
          cross_series_reducer = optional(string, "")           # REDUCE_MEAN | REDUCE_MAX | REDUCE_SUM | REDUCE_COUNT | REDUCE_NONE; empty = no reduction
          group_by_fields      = optional(list(string), [])     # resource/metric label fields to group by
        })), [])
      }), null)

      # Absent condition: fires when time series data disappears for the specified duration
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

      # Log-based condition: fires once per matching structured log entry
      condition_matched_log = optional(object({
        filter           = string                    # Cloud Logging filter expression
        label_extractors = optional(map(string), {}) # extract label values from log entries
      }), null)
    }))

    # Controls incident auto-close timing and repeat notification rate
    alert_strategy = optional(object({
      auto_close = optional(string, "604800s") # seconds until open incidents auto-close (default 7 days)
      notification_rate_limit = optional(object({
        period = optional(string, "3600s") # minimum time between repeat notifications for the same incident
      }), null)
    }), null)

    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.alert_policies : p.key])) == length(var.alert_policies)
    error_message = "alert_policies[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for p in var.alert_policies : contains(["OR", "AND", "AND_WITH_MATCHING_RESOURCE"], p.combiner)
    ])
    error_message = "alert_policies[*].combiner must be OR, AND, or AND_WITH_MATCHING_RESOURCE."
  }

  validation {
    condition = alltrue([
      for p in var.alert_policies : length(p.conditions) > 0
    ])
    error_message = "Each alert policy must have at least one condition."
  }
}

# ── Uptime Checks ──────────────────────────────────────────────────────────────

variable "uptime_checks" {
  description = "List of uptime check configurations. Each entry periodically probes an HTTP/S endpoint or TCP port from GCP's global checker network."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    display_name = string
    timeout      = optional(string, "10s")                # max time to wait for a response; must be <= period
    period       = optional(string, "60s")                # check frequency: 60s | 300s | 600s | 900s | 1800s | 3600s
    checker_type = optional(string, "STATIC_IP_CHECKERS") # STATIC_IP_CHECKERS | VPC_CHECKERS

    # Restrict checks to specific regions; empty = all global regions
    selected_regions = optional(list(string), []) # USA | EUROPE | ASIA_PACIFIC | SOUTH_AMERICA

    # HTTP/S probe settings
    http_check = optional(object({
      path           = optional(string, "/")
      port           = optional(number, 443)
      use_ssl        = optional(bool, true)
      validate_ssl   = optional(bool, true)
      request_method = optional(string, "GET") # GET | POST
      headers        = optional(map(string), {})

      # Override which HTTP status codes are treated as success; empty = accept 2xx
      accepted_response_status_codes = optional(list(object({
        status_class = optional(string, "STATUS_CLASS_2XX") # STATUS_CLASS_1XX | STATUS_CLASS_2XX | STATUS_CLASS_3XX | STATUS_CLASS_4XX | STATUS_CLASS_5XX | STATUS_CLASS_ANY
        status_value = optional(number, 0)                  # specific code (e.g. 200); 0 = use status_class
      })), [])
    }), null)

    # TCP port probe: checks that a connection can be established
    tcp_check = optional(object({
      port = number
    }), null)

    # Specific monitored resource to probe
    monitored_resource = optional(object({
      type   = string      # uptime_url | gce_instance | gae_app | aws_ec2_instance
      labels = map(string) # resource labels e.g. { host = "example.com" } for uptime_url
    }), null)

    # Alternative: probe an entire resource group
    resource_group = optional(object({
      group_id      = optional(string, "")
      resource_type = optional(string, "INSTANCE") # INSTANCE | AWS_ELB_LOAD_BALANCER
    }), null)

    # Optional assertions on the response body content
    content_matchers = optional(list(object({
      content = string
      matcher = optional(string, "CONTAINS_STRING") # CONTAINS_STRING | NOT_CONTAINS_STRING | MATCHES_REGEX | NOT_MATCHES_REGEX
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for u in var.uptime_checks : u.key])) == length(var.uptime_checks)
    error_message = "uptime_checks[*].key values must be unique."
  }
}

# ── Dashboards ─────────────────────────────────────────────────────────────────

variable "dashboards" {
  description = "List of monitoring dashboard configurations. Each entry uploads a raw JSON dashboard definition to Cloud Monitoring."
  type = list(object({
    key            = string
    create         = optional(bool, true)
    dashboard_json = string # complete JSON dashboard definition; export from the Cloud Monitoring console
  }))
  default = []

  validation {
    condition     = length(distinct([for d in var.dashboards : d.key])) == length(var.dashboards)
    error_message = "dashboards[*].key values must be unique."
  }
}
