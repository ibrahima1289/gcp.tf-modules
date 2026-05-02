# ===========================================================================
# Step 1: Pub/Sub Schemas (optional)
# Schemas enforce message structure (Avro or Protocol Buffers) at publish time.
# Created before topics so topics can reference them by ID.
# ===========================================================================
resource "google_pubsub_schema" "schemas" {
  for_each = { for s in var.schemas : s.key => s if s.create }

  project    = var.project_id
  name       = each.value.name
  type       = each.value.type
  definition = each.value.definition
}

# ===========================================================================
# Step 2: Pub/Sub Topics
# Topics are the central channel publishers send messages to.
# CMEK, message retention, and schema attachment are all optional.
# ===========================================================================
resource "google_pubsub_topic" "topics" {
  for_each = { for t in var.topics : t.key => t if t.create }

  project = var.project_id
  name    = each.value.name
  labels  = local.common_labels

  # Optional: retain unacknowledged messages on the topic for the given duration.
  # Consumers can seek back to any timestamp within the retention window.
  message_retention_duration = trimspace(each.value.message_retention_duration) != "" ? each.value.message_retention_duration : null

  # Optional: Cloud KMS key for customer-managed encryption of messages at rest.
  kms_key_name = trimspace(each.value.kms_key_name) != "" ? each.value.kms_key_name : null

  # Optional: restrict which regions may store message data (data residency).
  dynamic "message_storage_policy" {
    for_each = length(each.value.allowed_persistence_regions) > 0 ? [1] : []
    content {
      allowed_persistence_regions = each.value.allowed_persistence_regions
    }
  }

  # Optional: attach a schema to enforce message format at publish time.
  dynamic "schema_settings" {
    for_each = trimspace(each.value.schema_key) != "" ? [1] : []
    content {
      schema   = google_pubsub_schema.schemas[each.value.schema_key].id
      encoding = each.value.schema_encoding
    }
  }
}

# ===========================================================================
# Step 3: Dead-Letter Topics
# Dedicated topics that receive messages exceeding max delivery attempts.
# Created as plain topics; referenced by subscriptions in Step 4.
# ===========================================================================
resource "google_pubsub_topic" "dead_letter_topics" {
  for_each = {
    for s in var.subscriptions : s.dead_letter_key => s
    if s.create && trimspace(s.dead_letter_key) != ""
  }

  project = var.project_id
  name    = "${each.value.name}-dead-letter"
  labels  = local.common_labels
}

# ===========================================================================
# Step 4: Pub/Sub Subscriptions
# Subscriptions define how and where messages are delivered from a topic.
# Supports Pull, Push, BigQuery export, and Cloud Storage export.
# ===========================================================================
resource "google_pubsub_subscription" "subscriptions" {
  for_each = { for s in var.subscriptions : s.key => s if s.create }

  project = var.project_id
  name    = each.value.name
  topic   = google_pubsub_topic.topics[each.value.topic_key].id
  labels  = local.common_labels

  # How long the subscription retains unacknowledged messages (max 31 days).
  message_retention_duration = each.value.message_retention_duration

  # How long after delivery to wait for an ack before redelivering (10–600s).
  ack_deadline_seconds = each.value.ack_deadline_seconds

  # When true, messages published before the subscription was created are delivered.
  retain_acked_messages = each.value.retain_acked_messages

  # Subscription expires after this inactive duration. "never" = no expiry.
  dynamic "expiration_policy" {
    for_each = trimspace(each.value.expiration_ttl) != "" ? [1] : []
    content {
      ttl = each.value.expiration_ttl
    }
  }

  # Filter: only deliver messages matching this CEL expression.
  filter = trimspace(each.value.filter) != "" ? each.value.filter : null

  # Enable exactly-once delivery (requires streaming pull client library).
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery

  # Preserve message ordering when all publishers set an ordering_key.
  enable_message_ordering = each.value.enable_message_ordering

  # Retry policy controls minimum/maximum backoff between redelivery attempts.
  dynamic "retry_policy" {
    for_each = (trimspace(each.value.retry_minimum_backoff) != "" || trimspace(each.value.retry_maximum_backoff) != "") ? [1] : []
    content {
      minimum_backoff = trimspace(each.value.retry_minimum_backoff) != "" ? each.value.retry_minimum_backoff : "10s"
      maximum_backoff = trimspace(each.value.retry_maximum_backoff) != "" ? each.value.retry_maximum_backoff : "600s"
    }
  }

  # Dead-letter policy: route failed messages to the dead-letter topic after
  # max_delivery_attempts retries.
  dynamic "dead_letter_policy" {
    for_each = trimspace(each.value.dead_letter_key) != "" ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.dead_letter_topics[each.value.dead_letter_key].id
      max_delivery_attempts = each.value.dead_letter_max_delivery_attempts
    }
  }

  # ── Push config (optional) ───────────────────────────────────────────────
  # When push_endpoint is set, Pub/Sub HTTP POSTs each message to the URL.
  dynamic "push_config" {
    for_each = trimspace(each.value.push_endpoint) != "" ? [1] : []
    content {
      push_endpoint = each.value.push_endpoint

      # Attributes passed as HTTP headers to the push endpoint.
      attributes = each.value.push_attributes

      # OIDC token for authenticating push requests to Cloud Run / Cloud Functions.
      dynamic "oidc_token" {
        for_each = trimspace(each.value.push_oidc_service_account_email) != "" ? [1] : []
        content {
          service_account_email = each.value.push_oidc_service_account_email
          audience              = trimspace(each.value.push_oidc_audience) != "" ? each.value.push_oidc_audience : each.value.push_endpoint
        }
      }
    }
  }

  # ── BigQuery subscription (optional) ────────────────────────────────────
  # Writes messages directly into a BigQuery table without subscriber code.
  dynamic "bigquery_config" {
    for_each = trimspace(each.value.bigquery_table) != "" ? [1] : []
    content {
      table               = each.value.bigquery_table
      use_topic_schema    = each.value.bigquery_use_topic_schema
      write_metadata      = each.value.bigquery_write_metadata
      drop_unknown_fields = each.value.bigquery_drop_unknown_fields
    }
  }

  # ── Cloud Storage subscription (optional) ───────────────────────────────
  # Writes batches of messages to GCS as files on a configurable schedule.
  dynamic "cloud_storage_config" {
    for_each = trimspace(each.value.gcs_bucket) != "" ? [1] : []
    content {
      bucket          = each.value.gcs_bucket
      filename_prefix = trimspace(each.value.gcs_filename_prefix) != "" ? each.value.gcs_filename_prefix : null
      filename_suffix = trimspace(each.value.gcs_filename_suffix) != "" ? each.value.gcs_filename_suffix : null
      max_bytes       = each.value.gcs_max_bytes > 0 ? each.value.gcs_max_bytes : null
      max_duration    = trimspace(each.value.gcs_max_duration) != "" ? each.value.gcs_max_duration : null

      dynamic "avro_config" {
        for_each = each.value.gcs_avro_write_metadata ? [1] : []
        content {
          write_metadata = true
        }
      }
    }
  }
}

# ===========================================================================
# Step 5: Topic IAM bindings
# Grant publisher and/or subscriber roles to specific identities per topic.
# ===========================================================================
resource "google_pubsub_topic_iam_member" "topic_iam" {
  for_each = {
    for pair in flatten([
      for t in var.topics : [
        for binding in t.iam_bindings : {
          key    = "${t.key}/${binding.role}/${binding.member}"
          topic  = google_pubsub_topic.topics[t.key].name
          role   = binding.role
          member = binding.member
        }
      ]
      if t.create
    ]) : pair.key => pair
  }

  project = var.project_id
  topic   = each.value.topic
  role    = each.value.role
  member  = each.value.member
}

# ===========================================================================
# Step 6: Subscription IAM bindings
# Grant subscriber roles to specific identities per subscription.
# ===========================================================================
resource "google_pubsub_subscription_iam_member" "subscription_iam" {
  for_each = {
    for pair in flatten([
      for s in var.subscriptions : [
        for binding in s.iam_bindings : {
          key          = "${s.key}/${binding.role}/${binding.member}"
          subscription = google_pubsub_subscription.subscriptions[s.key].name
          role         = binding.role
          member       = binding.member
        }
      ]
      if s.create
    ]) : pair.key => pair
  }

  project      = var.project_id
  subscription = each.value.subscription
  role         = each.value.role
  member       = each.value.member
}
