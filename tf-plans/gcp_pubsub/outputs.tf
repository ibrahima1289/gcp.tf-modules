output "schema_ids" {
  description = "Pub/Sub schema IDs."
  value       = module.gcp_pubsub.schema_ids
}

output "topic_ids" {
  description = "Pub/Sub topic IDs."
  value       = module.gcp_pubsub.topic_ids
}

output "topic_names" {
  description = "Pub/Sub topic resource names."
  value       = module.gcp_pubsub.topic_names
}

output "dead_letter_topic_ids" {
  description = "Dead-letter topic IDs."
  value       = module.gcp_pubsub.dead_letter_topic_ids
}

output "subscription_ids" {
  description = "Pub/Sub subscription IDs."
  value       = module.gcp_pubsub.subscription_ids
}

output "subscription_names" {
  description = "Pub/Sub subscription resource names."
  value       = module.gcp_pubsub.subscription_names
}

output "common_labels" {
  description = "Common governance labels applied to all resources."
  value       = module.gcp_pubsub.common_labels
}
