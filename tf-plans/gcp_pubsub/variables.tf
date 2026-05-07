variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels merged with managed_by and created_date."
  type        = map(string)
  default     = {}
}

# Mirror the module's schemas variable exactly.
variable "schemas" {
  description = "List of Pub/Sub schema definitions."
  type = list(object({
    key        = string
    create     = optional(bool, true)
    name       = string
    type       = optional(string, "AVRO")
    definition = string
  }))
  default = []
}

# Mirror the module's topics variable exactly.
variable "topics" {
  description = "List of Pub/Sub topic definitions."
  type = list(object({
    key                         = string
    create                      = optional(bool, true)
    name                        = string
    message_retention_duration  = optional(string, "")
    kms_key_name                = optional(string, "")
    allowed_persistence_regions = optional(list(string), [])
    schema_key                  = optional(string, "")
    schema_encoding             = optional(string, "JSON")
    iam_bindings = optional(list(object({
      role   = string
      member = string
    })), [])
  }))
  default = []
}

# Mirror the module's subscriptions variable exactly.
variable "subscriptions" {
  description = "List of Pub/Sub subscription definitions."
  type = list(object({
    key                               = string
    create                            = optional(bool, true)
    name                              = string
    topic_key                         = string
    message_retention_duration        = optional(string, "604800s")
    ack_deadline_seconds              = optional(number, 20)
    retain_acked_messages             = optional(bool, false)
    expiration_ttl                    = optional(string, "")
    filter                            = optional(string, "")
    enable_message_ordering           = optional(bool, false)
    enable_exactly_once_delivery      = optional(bool, false)
    retry_minimum_backoff             = optional(string, "10s")
    retry_maximum_backoff             = optional(string, "600s")
    dead_letter_key                   = optional(string, "")
    dead_letter_max_delivery_attempts = optional(number, 5)
    push_endpoint                     = optional(string, "")
    push_attributes                   = optional(map(string), {})
    push_oidc_service_account_email   = optional(string, "")
    push_oidc_audience                = optional(string, "")
    bigquery_table                    = optional(string, "")
    bigquery_use_topic_schema         = optional(bool, false)
    bigquery_write_metadata           = optional(bool, false)
    bigquery_drop_unknown_fields      = optional(bool, false)
    gcs_bucket                        = optional(string, "")
    gcs_filename_prefix               = optional(string, "")
    gcs_filename_suffix               = optional(string, "")
    gcs_max_bytes                     = optional(number, 0)
    gcs_max_duration                  = optional(string, "")
    gcs_avro_write_metadata           = optional(bool, false)
    iam_bindings = optional(list(object({
      role   = string
      member = string
    })), [])
  }))
  default = []
}
