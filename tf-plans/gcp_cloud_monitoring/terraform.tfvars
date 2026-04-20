project_id = "main-project-492903"
region     = "us-central1"

tags = {
  owner       = "platform-team"
  environment = "production"
  team        = "platform"
}

# ── Notification Channels ──────────────────────────────────────────────────────
# Define delivery endpoints first; alert policies reference them by key.

notification_channels = [

  # Email channel — simplest type; no sensitive_labels required
  {
    key          = "ops-email"
    display_name = "Ops Team Email"
    type         = "email"
    labels       = { email_address = "ops@example.com" }
    enabled      = true
    create       = true
  },

  # Slack channel — requires a valid incoming webhook token.
  # Set create = true only after replacing auth_token with a real value from Secret Manager.
  {
    key          = "ops-slack"
    display_name = "Ops Slack #alerts"
    type         = "slack"
    labels       = { channel_name = "#alerts" }
    sensitive_labels = {
      auth_token  = "xoxb-replace-with-real-token" # replace before setting create = true
      password    = ""
      service_key = ""
    }
    enabled = true
    create  = false # set true only after supplying a valid auth_token
  },

  # PagerDuty channel — requires a service integration key
  {
    key          = "pagerduty-ops"
    display_name = "PagerDuty Ops Service"
    type         = "pagerduty"
    labels       = { channel_name = "ops-service" }
    sensitive_labels = {
      auth_token  = ""
      password    = ""
      service_key = "replace-with-pagerduty-key" # use Secret Manager in production
    }
    enabled = true
    create  = false # set true to activate
  },
]

# ── Alert Policies ─────────────────────────────────────────────────────────────

alert_policies = [

  # ── GCE CPU utilization threshold alert ─────────────────────────────────────
  # Fires when any GCE instance in the project sustains CPU > 80% for 5 minutes.
  {
    key                       = "high-cpu"
    display_name              = "GCE CPU Utilization > 80% (5 min)"
    combiner                  = "OR"
    enabled                   = true
    notification_channel_keys = ["ops-email", "ops-slack"]

    documentation_content = <<-MD
      ## High CPU Utilization
      A Compute Engine instance has sustained CPU utilization above **80%** for 5 minutes.

      **Immediate actions:**
      1. SSH into the instance and run `top` or `htop` to identify the process.
      2. Check Cloud Logging for application errors that may cause runaway processes.
      3. Consider scaling up the machine type or enabling Managed Instance Group autoscaling.

      **Runbook**: https://wiki.example.com/runbooks/high-cpu
    MD

    conditions = [
      {
        display_name = "CPU utilization > 0.8 for 5 min"
        condition_threshold = {
          filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
          duration        = "300s"
          comparison      = "COMPARISON_GT"
          threshold_value = 0.8

          aggregations = [
            {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_MEAN"
              cross_series_reducer = "REDUCE_MEAN"
              group_by_fields      = ["resource.labels.instance_id", "resource.labels.zone"]
            }
          ]
        }
      }
    ]

    alert_strategy = {
      auto_close = "86400s" # 1 day; notification_rate_limit not valid for metric-threshold policies
    }

    labels = { severity = "warning" }
    create = true
  },

  # ── Cloud Run request latency threshold alert ────────────────────────────────
  # Fires when p99 request latency exceeds 2 seconds over a 5-minute window.
  {
    key                       = "cloudrun-latency"
    display_name              = "Cloud Run p99 Latency > 2s"
    combiner                  = "OR"
    enabled                   = false
    notification_channel_keys = ["ops-email"]

    documentation_content = "Cloud Run service p99 request latency exceeded 2 seconds. Check service logs and consider scaling."

    conditions = [
      {
        display_name = "Cloud Run request latency p99 > 2s"
        condition_threshold = {
          filter          = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\""
          duration        = "300s"
          comparison      = "COMPARISON_GT"
          threshold_value = 2000 # milliseconds

          aggregations = [
            {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_PERCENTILE_99"
              cross_series_reducer = "REDUCE_MAX"
              group_by_fields      = ["resource.labels.service_name", "resource.labels.revision_name"]
            }
          ]
        }
      }
    ]

    alert_strategy = {
      auto_close = "604800s" # 7 days; notification_rate_limit not valid for metric-threshold policies
    }

    labels = { severity = "critical" }
    create = true
  },

  # ── Missing metric / data absent alert ─────────────────────────────────────
  # Fires if Cloud SQL instance stops reporting cpu/utilization for > 10 minutes.
  {
    key                       = "cloudsql-absent"
    display_name              = "Cloud SQL Metrics Absent > 10 min"
    combiner                  = "OR"
    enabled                   = true
    notification_channel_keys = ["ops-email"]
    documentation_content     = "Cloud SQL instance stopped reporting metrics. The instance may be stopped or in a failure state."

    conditions = [
      {
        display_name = "Cloud SQL cpu/utilization absent"
        condition_absent = {
          filter   = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" resource.type=\"cloudsql_database\""
          duration = "600s"

          aggregations = [
            {
              alignment_period   = "60s"
              per_series_aligner = "ALIGN_MEAN"
            }
          ]
        }
      }
    ]

    labels = { severity = "critical" }
    create = true
  },

  # ── Log-based error condition ───────────────────────────────────────────────
  # Fires on every ERROR or CRITICAL log entry from the application.
  {
    key                       = "app-errors"
    display_name              = "Application ERROR / CRITICAL Log Entries"
    combiner                  = "OR"
    enabled                   = true
    notification_channel_keys = ["ops-email", "ops-slack"]
    documentation_content     = "An ERROR or CRITICAL severity log entry was detected in the application. Check Cloud Logging for details."

    conditions = [
      {
        display_name = "ERROR or CRITICAL log entries"
        condition_matched_log = {
          filter = "severity >= ERROR AND resource.labels.project_id=\"my-project-id\""
          label_extractors = {
            "message" = "EXTRACT(jsonPayload.message)"
          }
        }
      }
    ]

    alert_strategy = {
      auto_close              = "86400s"
      notification_rate_limit = { period = "300s" } # max one notification per 5 min
    }

    labels = { severity = "warning" }
    create = true
  },

  # ── create = false example ──────────────────────────────────────────────────
  # Definition retained in config but no resource created.
  {
    key                       = "disk-throttle"
    display_name              = "GCE Disk Throttled Operations"
    combiner                  = "OR"
    notification_channel_keys = ["ops-email"]
    conditions = [
      {
        display_name = "Disk read/write throttled"
        condition_threshold = {
          filter          = "metric.type=\"compute.googleapis.com/instance/disk/throttled_read_ops_count\" resource.type=\"gce_instance\""
          duration        = "60s"
          comparison      = "COMPARISON_GT"
          threshold_value = 100
        }
      }
    ]
    create = false
  },
]

# ── Uptime Checks ──────────────────────────────────────────────────────────────

uptime_checks = [

  # ── HTTPS endpoint health check ─────────────────────────────────────────────
  # Probes /health every 60 seconds and verifies the response contains "status":"ok".
  {
    key          = "api-health"
    display_name = "API /health HTTPS Checks"
    timeout      = "10s"
    period       = "60s"
    checker_type = "STATIC_IP_CHECKERS"

    http_check = {
      path           = "/health"
      port           = 443
      use_ssl        = true
      validate_ssl   = true
      request_method = "GET"
      headers        = { "X-Uptime-Check" = "true" }
    }

    monitored_resource = {
      type   = "uptime_url"
      labels = { host = "api.example.com" }
    }

    content_matchers = [
      { content = "\"status\":\"ok\"", matcher = "CONTAINS_STRING" }
    ]

    create = true
  },

  # ── TCP port availability check ──────────────────────────────────────────────
  # Verifies that a PostgreSQL port is reachable from GCP's checker network.
  {
    key          = "db-tcp"
    display_name = "Database TCP Port 5432 Check"
    timeout      = "10s"
    period       = "300s" # check every 5 minutes

    tcp_check = { port = 5432 }

    monitored_resource = {
      type   = "uptime_url"
      labels = { host = "db.internal.example.com" }
    }

    create = false # enable when database host is publicly reachable or VPC Checkers are configured
  },
]

# ── Dashboards ─────────────────────────────────────────────────────────────────
# Dashboard JSON definitions are loaded from files under the dashboards/ folder.
# Add a new .json file there and register it in locals.tf → file_dashboards.
# To add an inline dashboard (without a file), append an entry here:
#
# dashboards = [
#   {
#     key            = "my-extra-dashboard"
#     create         = true
#     dashboard_json = <<-JSON
#       { "displayName": "My Dashboard", ... }
#     JSON
#   },
# ]

dashboards = []
