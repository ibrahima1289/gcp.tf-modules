# ── Notification Channels ─────────────────────────────────────────────────────
# Each channel entry creates one delivery endpoint for alert notifications.
resource "google_monitoring_notification_channel" "channel" {
  for_each = local.channels_map

  project      = var.project_id
  display_name = each.value.display_name
  type         = each.value.type   # email | slack | pagerduty | pubsub | webhook_tokenauth | sms
  labels       = each.value.labels # type-specific config keys (e.g. email_address, channel_name, topic)
  enabled      = each.value.enabled
  user_labels  = merge(local.common_labels, each.value.user_labels)

  # Sensitive credentials (auth tokens, service keys) are only set when provided
  dynamic "sensitive_labels" {
    for_each = (
      each.value.sensitive_labels != null && (
        trimspace(coalesce(each.value.sensitive_labels.auth_token, "")) != "" ||
        trimspace(coalesce(each.value.sensitive_labels.password, "")) != "" ||
        trimspace(coalesce(each.value.sensitive_labels.service_key, "")) != ""
      )
    ) ? [1] : []
    content {
      auth_token  = try(trimspace(each.value.sensitive_labels.auth_token), "") != "" ? each.value.sensitive_labels.auth_token : null
      password    = try(trimspace(each.value.sensitive_labels.password), "") != "" ? each.value.sensitive_labels.password : null
      service_key = try(trimspace(each.value.sensitive_labels.service_key), "") != "" ? each.value.sensitive_labels.service_key : null
    }
  }
}

# ── Alert Policies ─────────────────────────────────────────────────────────────
# Each policy defines one or more conditions; all channels in notification_channel_keys
# are notified when the policy fires.
resource "google_monitoring_alert_policy" "policy" {
  for_each = local.alert_policies_map

  project      = var.project_id
  display_name = each.value.display_name
  combiner     = each.value.combiner # OR | AND | AND_WITH_MATCHING_RESOURCE
  enabled      = each.value.enabled
  user_labels  = merge(local.common_labels, each.value.labels)

  # Resolve notification channel keys to full resource names created above.
  # Keys whose channel has create = false are silently skipped to avoid index errors.
  notification_channels = [
    for ch_key in each.value.notification_channel_keys :
    google_monitoring_notification_channel.channel[ch_key].name
    if contains(keys(google_monitoring_notification_channel.channel), ch_key)
  ]

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name

      # Threshold condition: fires when a metric value exceeds or drops below a threshold
      dynamic "condition_threshold" {
        for_each = conditions.value.condition_threshold != null ? [conditions.value.condition_threshold] : []
        content {
          filter          = condition_threshold.value.filter          # MQL filter selecting the time series
          duration        = condition_threshold.value.duration        # violation must persist this long before firing
          comparison      = condition_threshold.value.comparison      # COMPARISON_GT | COMPARISON_LT | COMPARISON_GE | COMPARISON_LE
          threshold_value = condition_threshold.value.threshold_value # numeric threshold value

          dynamic "aggregations" {
            for_each = condition_threshold.value.aggregations
            content {
              alignment_period     = aggregations.value.alignment_period
              per_series_aligner   = aggregations.value.per_series_aligner
              cross_series_reducer = trimspace(aggregations.value.cross_series_reducer) != "" ? aggregations.value.cross_series_reducer : null
              group_by_fields      = length(aggregations.value.group_by_fields) > 0 ? aggregations.value.group_by_fields : null
            }
          }
        }
      }

      # Absent condition: fires when time series data disappears for the specified duration
      dynamic "condition_absent" {
        for_each = conditions.value.condition_absent != null ? [conditions.value.condition_absent] : []
        content {
          filter   = condition_absent.value.filter
          duration = condition_absent.value.duration

          dynamic "aggregations" {
            for_each = condition_absent.value.aggregations
            content {
              alignment_period     = aggregations.value.alignment_period
              per_series_aligner   = aggregations.value.per_series_aligner
              cross_series_reducer = trimspace(aggregations.value.cross_series_reducer) != "" ? aggregations.value.cross_series_reducer : null
              group_by_fields      = length(aggregations.value.group_by_fields) > 0 ? aggregations.value.group_by_fields : null
            }
          }
        }
      }

      # Log-based condition: fires on each matching structured log entry
      dynamic "condition_matched_log" {
        for_each = conditions.value.condition_matched_log != null ? [conditions.value.condition_matched_log] : []
        content {
          filter           = condition_matched_log.value.filter
          label_extractors = length(condition_matched_log.value.label_extractors) > 0 ? condition_matched_log.value.label_extractors : null
        }
      }
    }
  }

  # Optional Markdown run-book shown in the alert detail pane and notification messages
  dynamic "documentation" {
    for_each = trimspace(each.value.documentation_content) != "" ? [1] : []
    content {
      content   = each.value.documentation_content
      mime_type = "text/markdown"
    }
  }

  # Controls incident auto-close timing and repeat notification rate limiting.
  # notification_rate_limit is only valid for log-based alert policies (condition_matched_log).
  dynamic "alert_strategy" {
    for_each = each.value.alert_strategy != null ? [each.value.alert_strategy] : []
    content {
      auto_close = trimspace(alert_strategy.value.auto_close) != "" ? alert_strategy.value.auto_close : null

      dynamic "notification_rate_limit" {
        for_each = (
          alert_strategy.value.notification_rate_limit != null &&
          anytrue([for c in each.value.conditions : c.condition_matched_log != null])
        ) ? [alert_strategy.value.notification_rate_limit] : []
        content {
          period = notification_rate_limit.value.period
        }
      }
    }
  }
}

# ── Uptime Checks ──────────────────────────────────────────────────────────────
# Periodically probe HTTP/S endpoints or TCP ports from GCP's global checker network.
resource "google_monitoring_uptime_check_config" "uptime_check" {
  for_each = local.uptime_checks_map

  project      = var.project_id
  display_name = each.value.display_name
  timeout      = each.value.timeout      # max wait per probe (e.g. "10s")
  period       = each.value.period       # probe frequency: 60s | 300s | 600s | 900s | 1800s | 3600s
  checker_type = each.value.checker_type # STATIC_IP_CHECKERS | VPC_CHECKERS

  selected_regions = length(each.value.selected_regions) > 0 ? each.value.selected_regions : null

  # HTTP/S probe: path, port, SSL validation, request method, custom headers
  dynamic "http_check" {
    for_each = each.value.http_check != null ? [each.value.http_check] : []
    content {
      path           = http_check.value.path
      port           = http_check.value.port
      use_ssl        = http_check.value.use_ssl
      validate_ssl   = http_check.value.validate_ssl
      request_method = http_check.value.request_method
      headers        = length(http_check.value.headers) > 0 ? http_check.value.headers : null

      # Optional list of accepted HTTP status codes; empty = accept 2xx only
      dynamic "accepted_response_status_codes" {
        for_each = http_check.value.accepted_response_status_codes
        content {
          status_class = trimspace(accepted_response_status_codes.value.status_class) != "" ? accepted_response_status_codes.value.status_class : null
          status_value = accepted_response_status_codes.value.status_value > 0 ? accepted_response_status_codes.value.status_value : null
        }
      }
    }
  }

  # TCP port probe: simply checks that a connection can be established
  dynamic "tcp_check" {
    for_each = each.value.tcp_check != null ? [each.value.tcp_check] : []
    content {
      port = tcp_check.value.port
    }
  }

  # Specific monitored resource to probe (e.g. uptime_url with host label)
  dynamic "monitored_resource" {
    for_each = each.value.monitored_resource != null ? [each.value.monitored_resource] : []
    content {
      type   = monitored_resource.value.type # uptime_url | gce_instance | gae_app
      labels = monitored_resource.value.labels
    }
  }

  # Alternative: probe a resource group instead of a single target
  dynamic "resource_group" {
    for_each = each.value.resource_group != null ? [each.value.resource_group] : []
    content {
      group_id      = trimspace(resource_group.value.group_id) != "" ? resource_group.value.group_id : null
      resource_type = resource_group.value.resource_type
    }
  }

  # Optional response body content assertions
  dynamic "content_matchers" {
    for_each = each.value.content_matchers
    content {
      content = content_matchers.value.content
      matcher = content_matchers.value.matcher
    }
  }
}

# ── Dashboards ──────────────────────────────────────────────────────────────────
# Each entry uploads a raw JSON dashboard definition to Cloud Monitoring.
resource "google_monitoring_dashboard" "dashboard" {
  for_each = local.dashboards_map

  project        = var.project_id
  dashboard_json = each.value.dashboard_json # complete JSON definition; export from the Cloud Monitoring console
}
