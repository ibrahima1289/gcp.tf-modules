# ---------------------------------------------------------------------------
# GCP project where all Pub/Sub resources are created.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID where all Pub/Sub resources are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Region is carried through for provider consistency; Pub/Sub topics are
# global but subscriptions with BigQuery/GCS configs reference regional resources.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region (used by provider and BigQuery/GCS subscription references)."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels applied to all topics and subscriptions.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date in locals."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Pub/Sub Schema definitions.
# Schemas enforce Avro or Protobuf message structure at publish time.
# ---------------------------------------------------------------------------
variable "schemas" {
  description = "List of Pub/Sub schema definitions."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry for reference.
    create = optional(bool, true)
    # Schema resource name.
    name = string
    # Schema type: "AVRO" or "PROTOCOL_BUFFER".
    type = optional(string, "AVRO")
    # Schema definition JSON (Avro) or text (Protobuf).
    definition = string
  }))

  default = []

  validation {
    condition     = length([for s in var.schemas : s.key]) == length(toset([for s in var.schemas : s.key]))
    error_message = "Each schema entry must have a unique key."
  }
}

# ---------------------------------------------------------------------------
# Pub/Sub Topic definitions.
# Each entry creates one google_pubsub_topic resource plus optional
# schema attachment, CMEK, message retention, and IAM bindings.
# ---------------------------------------------------------------------------
variable "topics" {
  description = "List of Pub/Sub topic definitions."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry for reference.
    create = optional(bool, true)
    # Topic resource name.
    name = string

    # ---------------------------------------------------------------------------
    # Message retention
    # ---------------------------------------------------------------------------
    # Duration to retain unacknowledged messages on the topic (ISO 8601 duration).
    # Enables seek-to-timestamp for subscriptions. Leave empty to disable.
    # Range: "600s" (10m) – "2678400s" (31 days).
    message_retention_duration = optional(string, "")

    # ---------------------------------------------------------------------------
    # Encryption
    # ---------------------------------------------------------------------------
    # Cloud KMS key for CMEK encryption of messages at rest.
    # Format: "projects/{project}/locations/{location}/keyRings/{ring}/cryptoKeys/{key}"
    kms_key_name = optional(string, "")

    # ---------------------------------------------------------------------------
    # Data residency
    # ---------------------------------------------------------------------------
    # List of GCP regions where message data is allowed to be stored.
    # Empty list = no restriction (Google-chosen regions).
    allowed_persistence_regions = optional(list(string), [])

    # ---------------------------------------------------------------------------
    # Schema attachment
    # ---------------------------------------------------------------------------
    # Key of a schema entry in var.schemas to attach to this topic.
    # Leave empty to disable schema validation.
    schema_key = optional(string, "")
    # Message encoding for the attached schema: "JSON" or "BINARY".
    schema_encoding = optional(string, "JSON")

    # ---------------------------------------------------------------------------
    # IAM bindings
    # ---------------------------------------------------------------------------
    # Publisher / subscriber IAM bindings for this topic.
    iam_bindings = optional(list(object({
      role   = string # e.g. "roles/pubsub.publisher"
      member = string # e.g. "serviceAccount:sa@project.iam.gserviceaccount.com"
    })), [])
  }))

  default = []

  validation {
    condition     = length([for t in var.topics : t.key]) == length(toset([for t in var.topics : t.key]))
    error_message = "Each topic entry must have a unique key."
  }
}

# ---------------------------------------------------------------------------
# Pub/Sub Subscription definitions.
# Each entry creates one google_pubsub_subscription. Subscription type
# (Pull / Push / BigQuery / GCS) is determined by which optional fields are set.
# ---------------------------------------------------------------------------
variable "subscriptions" {
  description = "List of Pub/Sub subscription definitions."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry for reference.
    create = optional(bool, true)
    # Subscription resource name.
    name = string
    # Key of the topic in var.topics this subscription receives from.
    topic_key = string

    # ---------------------------------------------------------------------------
    # Delivery settings
    # ---------------------------------------------------------------------------
    # How long unacknowledged messages are retained (max "2678400s" = 31 days).
    message_retention_duration = optional(string, "604800s") # 7 days
    # How long to wait for an ack before redelivering (10–600 seconds).
    ack_deadline_seconds = optional(number, 20)
    # Retain acknowledged messages within the retention window (enables replay).
    retain_acked_messages = optional(bool, false)
    # Subscription TTL — delete after inactivity. Use "never" for no expiry.
    expiration_ttl = optional(string, "")
    # CEL filter expression — only messages matching this expression are delivered.
    filter = optional(string, "")

    # ---------------------------------------------------------------------------
    # Ordering and exactly-once
    # ---------------------------------------------------------------------------
    # Require publishers to set an ordering_key and deliver in FIFO order per key.
    enable_message_ordering = optional(bool, false)
    # Guarantee at-most-once delivery (requires streaming pull + ack with ack IDs).
    enable_exactly_once_delivery = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Retry policy
    # ---------------------------------------------------------------------------
    # Minimum delay before redelivering an unacknowledged message (ISO 8601).
    retry_minimum_backoff = optional(string, "10s")
    # Maximum delay before redelivering an unacknowledged message.
    retry_maximum_backoff = optional(string, "600s")

    # ---------------------------------------------------------------------------
    # Dead-letter policy
    # ---------------------------------------------------------------------------
    # Key suffix used to derive the dead-letter topic name (<name>-dead-letter).
    # Leave empty to disable dead-lettering.
    dead_letter_key = optional(string, "")
    # Number of delivery attempts before routing to the dead-letter topic.
    dead_letter_max_delivery_attempts = optional(number, 5)

    # ---------------------------------------------------------------------------
    # Push subscription (mutually exclusive with BigQuery / GCS)
    # ---------------------------------------------------------------------------
    # HTTPS URL that Pub/Sub calls for each message. Leave empty for pull.
    push_endpoint = optional(string, "")
    # HTTP attributes passed alongside the push request.
    push_attributes = optional(map(string), {})
    # Service account whose OIDC token authenticates push requests.
    push_oidc_service_account_email = optional(string, "")
    # Audience for the OIDC token (defaults to push_endpoint if empty).
    push_oidc_audience = optional(string, "")

    # ---------------------------------------------------------------------------
    # BigQuery subscription (mutually exclusive with Push / GCS)
    # ---------------------------------------------------------------------------
    # Fully qualified BigQuery table: "project.dataset.table"
    bigquery_table = optional(string, "")
    # Use topic's schema to decode messages into BigQuery columns.
    bigquery_use_topic_schema = optional(bool, false)
    # Write Pub/Sub message metadata (message_id, publish_time, etc.) as columns.
    bigquery_write_metadata = optional(bool, false)
    # Drop fields not present in the BigQuery table schema.
    bigquery_drop_unknown_fields = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Cloud Storage subscription (mutually exclusive with Push / BigQuery)
    # ---------------------------------------------------------------------------
    # GCS bucket name. Leave empty to disable GCS subscription.
    gcs_bucket = optional(string, "")
    # Optional filename prefix for stored message files.
    gcs_filename_prefix = optional(string, "")
    # Optional filename suffix (e.g. ".json").
    gcs_filename_suffix = optional(string, "")
    # Max file size in bytes before rotating to a new file (0 = provider default).
    gcs_max_bytes = optional(number, 0)
    # Max duration before closing and writing a file (ISO 8601, e.g. "300s").
    gcs_max_duration = optional(string, "")
    # Include Pub/Sub message metadata in Avro output files.
    gcs_avro_write_metadata = optional(bool, false)

    # ---------------------------------------------------------------------------
    # IAM bindings
    # ---------------------------------------------------------------------------
    # Subscriber IAM bindings for this subscription.
    iam_bindings = optional(list(object({
      role   = string
      member = string
    })), [])
  }))

  default = []

  validation {
    condition     = length([for s in var.subscriptions : s.key]) == length(toset([for s in var.subscriptions : s.key]))
    error_message = "Each subscription entry must have a unique key."
  }
}
