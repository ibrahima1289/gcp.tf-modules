# ── Log Buckets ────────────────────────────────────────────────────────────────
# Custom log storage containers with configurable retention and optional Log Analytics.
# The built-in _Required and _Default buckets are managed by GCP and cannot be deleted.
resource "google_logging_project_bucket_config" "bucket" {
  for_each = local.log_buckets_map

  project        = var.project_id
  location       = each.value.location       # global | region (e.g. us-central1)
  bucket_id      = each.value.bucket_id      # unique ID within the project
  retention_days = each.value.retention_days # 1–3650; _Required minimum is 400
  description    = each.value.description
  locked         = each.value.locked # prevent retention reduction or deletion

  # Enable Log Analytics: allows SQL queries over log data via BigQuery-linked dataset
  enable_analytics = each.value.enable_analytics

  # Optional CMEK: encrypt stored logs with a customer-managed Cloud KMS key
  dynamic "cmek_settings" {
    for_each = trimspace(each.value.kms_key_name) != "" ? [1] : []
    content {
      kms_key_name = each.value.kms_key_name
    }
  }
}

# ── Log Sinks ──────────────────────────────────────────────────────────────────
# Route filtered log streams to an external destination (GCS, BigQuery, Pub/Sub, log bucket).
# Set unique_writer_identity = true to get a per-sink service account for destination IAM.
resource "google_logging_project_sink" "sink" {
  for_each = local.sinks_map

  project                = var.project_id
  name                   = each.value.name
  destination            = each.value.destination # "storage.googleapis.com/<bucket>" | "bigquery.googleapis.com/projects/<p>/datasets/<ds>" | "pubsub.googleapis.com/projects/<p>/topics/<t>" | "logging.googleapis.com/projects/<p>/locations/<l>/buckets/<b>"
  filter                 = each.value.filter      # Cloud Logging filter; empty string exports all logs
  description            = each.value.description
  unique_writer_identity = each.value.unique_writer_identity # true = dedicated SA; false = shared logging SA

  # BigQuery-specific options; only set when the destination is a BigQuery dataset
  dynamic "bigquery_options" {
    for_each = each.value.bigquery_options != null ? [each.value.bigquery_options] : []
    content {
      # Partition tables by log entry timestamp for cheaper queries and longer data lifecycle
      use_partitioned_tables = bigquery_options.value.use_partitioned_tables
    }
  }

  # Per-sink exclusions: drop matching entries before they reach the destination
  dynamic "exclusions" {
    for_each = each.value.exclusions
    content {
      name        = exclusions.value.name
      description = exclusions.value.description
      filter      = exclusions.value.filter
      disabled    = exclusions.value.disabled
    }
  }
}

# ── Log Exclusions ─────────────────────────────────────────────────────────────
# Drop matching log entries project-wide before they are ingested into any sink.
# Use exclusions to remove noisy, low-value logs and reduce ingestion cost.
resource "google_logging_project_exclusion" "exclusion" {
  for_each = local.exclusions_map

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  filter      = each.value.filter   # Cloud Logging filter expression for entries to drop
  disabled    = each.value.disabled # set true to temporarily re-enable without deleting
}

# ── Log-Based Metrics ──────────────────────────────────────────────────────────
# Convert structured log entries into Cloud Monitoring metrics for alerting and dashboards.
# Counters (INT64 DELTA) or distributions (DISTRIBUTION DELTA) are supported.
resource "google_logging_metric" "metric" {
  for_each = local.metrics_map

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  filter      = each.value.filter # Cloud Logging filter selecting the entries to count/measure

  # Descriptor defines the metric type, value type, and optional label schema
  metric_descriptor {
    metric_kind = each.value.metric_kind # DELTA | GAUGE | CUMULATIVE
    value_type  = each.value.value_type  # INT64 | DISTRIBUTION | BOOL | STRING | DOUBLE

    # Labels enable slicing the metric by log entry fields (e.g. severity, resource.type)
    dynamic "labels" {
      for_each = each.value.labels
      content {
        key         = labels.value.key
        value_type  = labels.value.value_type # STRING | BOOL | INT64
        description = labels.value.description
      }
    }

    unit         = each.value.unit # "1" for unitless counts; "ms" for latency etc.
    display_name = each.value.display_name
  }

  # label_extractors map log entry field paths to metric label keys
  label_extractors = length(each.value.label_extractors) > 0 ? each.value.label_extractors : null

  # value_extractor is only valid for DISTRIBUTION metrics; extracts the numeric value to measure
  value_extractor = trimspace(each.value.value_extractor) != "" ? each.value.value_extractor : null

  # Optional histogram bucket definition for DISTRIBUTION metrics
  dynamic "bucket_options" {
    for_each = each.value.bucket_options != null ? [each.value.bucket_options] : []
    content {
      dynamic "linear_buckets" {
        for_each = bucket_options.value.linear_buckets != null ? [bucket_options.value.linear_buckets] : []
        content {
          num_finite_buckets = linear_buckets.value.num_finite_buckets
          width              = linear_buckets.value.width
          offset             = linear_buckets.value.offset
        }
      }
      dynamic "exponential_buckets" {
        for_each = bucket_options.value.exponential_buckets != null ? [bucket_options.value.exponential_buckets] : []
        content {
          num_finite_buckets = exponential_buckets.value.num_finite_buckets
          growth_factor      = exponential_buckets.value.growth_factor
          scale              = exponential_buckets.value.scale
        }
      }
      dynamic "explicit_buckets" {
        for_each = bucket_options.value.explicit_buckets != null ? [bucket_options.value.explicit_buckets] : []
        content {
          bounds = explicit_buckets.value.bounds
        }
      }
    }
  }
}
