project_id = "main-project-492903"
region     = "us-east1"

tags = {
  env     = "dev"
  team    = "platform"
  owner   = "infra-team"
  project = "main-project-492903"
}

# ===========================================================================
# Schemas
# ===========================================================================
schemas = [
  # Avro schema enforces telemetry message structure at publish time.
  {
    key        = "telemetry"
    create     = true
    name       = "telemetry-schema"
    type       = "AVRO"
    definition = "{\"type\":\"record\",\"name\":\"Telemetry\",\"fields\":[{\"name\":\"device_id\",\"type\":\"string\"},{\"name\":\"temperature\",\"type\":\"float\"},{\"name\":\"timestamp\",\"type\":\"long\"}]}"
  }
]

# ===========================================================================
# Topics
# ===========================================================================
topics = [
  # ── Order events topic — pub/sub for e-commerce order pipeline ────────────
  {
    key    = "orders"
    create = false
    name   = "orders"
    # 1-day topic retention enables seek-to-timestamp for all subscriptions.
    message_retention_duration = "86400s"
    iam_bindings = [
      {
        role   = "roles/pubsub.publisher"
        member = "serviceAccount:order-svc@main-project-492903.iam.gserviceaccount.com"
      }
    ]
  },

  # ── IoT telemetry topic — uses Avro schema for structured data ────────────
  {
    key             = "telemetry"
    create          = false
    name            = "iot-telemetry"
    schema_key      = "telemetry"
    schema_encoding = "BINARY" # Can also be JSON, but BINARY is more compact for Avro messages.
    # Restrict message storage to a specific region for data residency.
    allowed_persistence_regions = ["us-central1"]
    iam_bindings = [
      {
        role   = "roles/pubsub.publisher"
        member = "serviceAccount:iot-gateway@main-project-492903.iam.gserviceaccount.com"
      }
    ]
  },

  # ── Application events topic — used by push + GCS subscriptions ───────────
  {
    key             = "app-events"
    create          = true
    name            = "application-events"
    schema_key      = "telemetry"
    schema_encoding = "JSON"
  }
]

# ===========================================================================
# Subscriptions
# ===========================================================================
subscriptions = [
  # ── Pull subscription — order worker service polls for messages ───────────
  {
    key                        = "orders-worker"
    create                     = false
    name                       = "orders-worker"
    topic_key                  = "orders"
    ack_deadline_seconds       = 60
    message_retention_duration = "604800s" # 7 days
    # Dead-letter topic created automatically as "orders-worker-dead-letter".
    dead_letter_key                   = "orders-worker"
    dead_letter_max_delivery_attempts = 5
    retry_minimum_backoff             = "10s"
    retry_maximum_backoff             = "300s"
    iam_bindings = [
      {
        role   = "roles/pubsub.subscriber"
        member = "serviceAccount:order-worker@main-project-492903.iam.gserviceaccount.com"
      }
    ]
  },

  # ── Push subscription — Cloud Run service receives events via HTTP POST ───
  {
    key           = "app-events-push"
    create        = false
    name          = "app-events-push"
    topic_key     = "app-events"
    push_endpoint = "https://event-handler-xyz-uc.a.run.app/pubsub"
    # OIDC token authenticates the push request to the Cloud Run endpoint.
    push_oidc_service_account_email = "pubsub-invoker@main-project-492903.iam.gserviceaccount.com"
    ack_deadline_seconds            = 30
  },

  # ── BigQuery subscription — IoT telemetry written directly to BQ ─────────
  # The BQ table must exist and match the Avro schema columns.
  {
    key                       = "telemetry-bq"
    create                    = false
    name                      = "telemetry-bq"
    topic_key                 = "telemetry"
    bigquery_table            = "my-gcp-project.iot_dataset.telemetry_raw"
    bigquery_use_topic_schema = true
    bigquery_write_metadata   = true
    ack_deadline_seconds      = 20
  },

  # ── Cloud Storage subscription — app events archived to GCS as JSON files ─
  {
    key                  = "app-events-gcs"
    create               = false
    name                 = "app-events-gcs"
    topic_key            = "app-events"
    gcs_bucket           = "my-gcp-project-event-archive"
    gcs_filename_prefix  = "events/"
    gcs_filename_suffix  = ".json"
    gcs_max_bytes        = 10485760 # 10 MiB per file
    gcs_max_duration     = "300s"   # rotate every 5 minutes
    ack_deadline_seconds = 60
  }
]
