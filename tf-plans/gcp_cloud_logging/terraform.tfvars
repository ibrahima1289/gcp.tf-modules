project_id = "main-project-492903"
region     = "us-central1"

tags = {
  owner       = "platform-team"
  environment = "production"
  team        = "platform"
}

# ── Log Buckets ────────────────────────────────────────────────────────────────
# Custom storage containers for logs with configurable retention and Log Analytics.

log_buckets = [

  # Security and audit log bucket with 1-year retention and Log Analytics enabled
  {
    key              = "security-logs"
    bucket_id        = "security-logs"
    location         = "us-central1"
    retention_days   = 365
    description      = "Security and audit logs with Log Analytics for SQL-based investigation"
    enable_analytics = true
    locked           = false
    create           = true
  },

  # Application log bucket with 90-day retention for ops debugging
  {
    key              = "app-logs"
    bucket_id        = "app-logs"
    location         = "us-central1"
    retention_days   = 90
    description      = "Application and service logs for operational debugging"
    enable_analytics = false
    create           = true
  },
]

# ── Log Sinks ──────────────────────────────────────────────────────────────────
# Export filtered log streams to external destinations.
# After apply, grant each sink's writer_identity the required role on the destination.

log_sinks = [

  # Export audit logs to BigQuery for SIEM and SQL analysis
  {
    key                    = "audit-to-bq"
    name                   = "audit-to-bigquery"
    destination            = "bigquery.googleapis.com/projects/main-project-492903/datasets/audit_logs"
    filter                 = "logName:(\"activity\" OR \"data_access\")"
    description            = "Route Admin Activity and Data Access logs to BigQuery for analysis"
    unique_writer_identity = true
    bigquery_options       = { use_partitioned_tables = true }
    create                 = true
  },

  # Export ERROR and CRITICAL logs to GCS for long-term compliance archival.
  # Set create = true only after the GCS bucket "main-project-log-archive" exists;
  # Google validates the destination at sink creation time and returns 404 otherwise.
  {
    key                    = "errors-to-gcs"
    name                   = "errors-to-gcs"
    destination            = "storage.googleapis.com/main-project-log-archive"
    filter                 = "severity >= ERROR"
    description            = "Archive ERROR and CRITICAL logs to GCS for compliance"
    unique_writer_identity = true
    create                 = false # set true after creating the destination GCS bucket
  },

  # Export all logs to a Pub/Sub topic for real-time SIEM integration (disabled by default)
  {
    key                    = "all-to-pubsub"
    name                   = "all-logs-to-pubsub"
    destination            = "pubsub.googleapis.com/projects/main-project-492903/topics/log-stream"
    filter                 = ""
    description            = "Stream all logs to Pub/Sub for real-time SIEM processing"
    unique_writer_identity = true
    create                 = false # enable when the Pub/Sub topic exists and IAM is granted
  },
]

# ── Log Exclusions ─────────────────────────────────────────────────────────────
# Drop matching log entries project-wide before ingestion to reduce cost.

log_exclusions = [

  # Drop GKE liveness probe 200 responses (very high volume, low value)
  {
    key         = "drop-health-check-200s"
    name        = "drop-health-check-200s"
    description = "Drop GKE ingress health check 200 OK responses to reduce ingestion volume"
    filter      = "resource.type=\"k8s_container\" httpRequest.status=200 httpRequest.requestUrl:\"/healthz\""
    disabled    = false
    create      = true
  },

  # Drop Cloud SQL routine operational messages
  {
    key         = "drop-cloudsql-info"
    name        = "drop-cloudsql-info"
    description = "Drop Cloud SQL INFO-level operational logs to reduce noise"
    filter      = "resource.type=\"cloudsql_database\" severity=INFO protoPayload.serviceName=\"cloudsql.googleapis.com\""
    disabled    = false
    create      = true
  },
]

# ── Log-Based Metrics ──────────────────────────────────────────────────────────
# Convert log entries into Cloud Monitoring metrics for alerting and dashboards.

log_metrics = [

  # Count IAM policy changes for security alerting
  {
    key          = "iam-changes"
    name         = "iam-policy-changes"
    description  = "Count of IAM SetIamPolicy calls — use for security alerting"
    filter       = "protoPayload.methodName=\"SetIamPolicy\""
    metric_kind  = "DELTA"
    value_type   = "INT64"
    display_name = "IAM Policy Changes"
    labels = [
      {
        key         = "resource_type"
        value_type  = "STRING"
        description = "The type of resource whose IAM policy was changed"
      }
    ]
    label_extractors = {
      resource_type = "EXTRACT(resource.type)"
    }
    create = true
  },

  # Count HTTP 5xx errors for application SLO alerting
  {
    key          = "http-5xx-errors"
    name         = "http-5xx-errors"
    description  = "Count of HTTP 5xx server error responses from Cloud Run and App Engine"
    filter       = "httpRequest.status>=500 httpRequest.status<600"
    metric_kind  = "DELTA"
    value_type   = "INT64"
    display_name = "HTTP 5xx Errors"
    labels = [
      {
        key         = "service"
        value_type  = "STRING"
        description = "Cloud Run service or App Engine module name"
      }
    ]
    label_extractors = {
      service = "EXTRACT(resource.labels.service_name)"
    }
    create = true
  },

  # Measure request latency distribution from Cloud Run structured logs (disabled by default)
  {
    key             = "request-latency"
    name            = "request-latency-ms"
    description     = "Distribution of request latency extracted from Cloud Run structured log entries"
    filter          = "resource.type=\"cloud_run_revision\" jsonPayload.latency!=\"\""
    metric_kind     = "DELTA"
    value_type      = "DISTRIBUTION"
    unit            = "ms"
    display_name    = "Request Latency (ms)"
    value_extractor = "EXTRACT(jsonPayload.latency)"
    bucket_options = {
      exponential_buckets = {
        num_finite_buckets = 20
        growth_factor      = 2.0
        scale              = 1.0
      }
      linear_buckets   = null
      explicit_buckets = null
    }
    create = false # enable after confirming jsonPayload.latency field is populated
  },
]
