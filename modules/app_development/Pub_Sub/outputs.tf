# ---------------------------------------------------------------------------
# Schema outputs
# ---------------------------------------------------------------------------
output "schema_ids" {
  description = "Pub/Sub schema IDs, keyed by schema key."
  value       = { for k, s in google_pubsub_schema.schemas : k => s.id }
}

# ---------------------------------------------------------------------------
# Topic outputs
# ---------------------------------------------------------------------------
output "topic_ids" {
  description = "Fully qualified Pub/Sub topic IDs, keyed by topic key."
  value       = { for k, t in google_pubsub_topic.topics : k => t.id }
}

output "topic_names" {
  description = "Pub/Sub topic resource names, keyed by topic key."
  value       = { for k, t in google_pubsub_topic.topics : k => t.name }
}

output "dead_letter_topic_ids" {
  description = "Dead-letter topic IDs, keyed by dead_letter_key."
  value       = { for k, t in google_pubsub_topic.dead_letter_topics : k => t.id }
}

# ---------------------------------------------------------------------------
# Subscription outputs
# ---------------------------------------------------------------------------
output "subscription_ids" {
  description = "Fully qualified subscription IDs, keyed by subscription key."
  value       = { for k, s in google_pubsub_subscription.subscriptions : k => s.id }
}

output "subscription_names" {
  description = "Subscription resource names, keyed by subscription key."
  value       = { for k, s in google_pubsub_subscription.subscriptions : k => s.name }
}

# ---------------------------------------------------------------------------
# Governance outputs
# ---------------------------------------------------------------------------
output "common_labels" {
  description = "Common governance labels applied to all resources."
  value       = local.common_labels
}
