output "notification_channel_ids" {
  description = "Notification channel resource IDs keyed by channel key."
  value       = module.gcp_cloud_monitoring.notification_channel_ids
}

output "notification_channel_names" {
  description = "Notification channel full resource names (for use in external alert policies)."
  value       = module.gcp_cloud_monitoring.notification_channel_names
}

output "alert_policy_ids" {
  description = "Alert policy resource IDs keyed by policy key."
  value       = module.gcp_cloud_monitoring.alert_policy_ids
}

output "alert_policy_names" {
  description = "Alert policy resource names keyed by policy key."
  value       = module.gcp_cloud_monitoring.alert_policy_names
}

output "uptime_check_ids" {
  description = "Uptime check resource IDs keyed by check key."
  value       = module.gcp_cloud_monitoring.uptime_check_ids
}

output "uptime_check_names" {
  description = "Uptime check resource names keyed by check key."
  value       = module.gcp_cloud_monitoring.uptime_check_names
}

output "uptime_check_uptime_check_ids" {
  description = "Short uptime check IDs for use in metric filters keyed by check key."
  value       = module.gcp_cloud_monitoring.uptime_check_uptime_check_ids
}

output "dashboard_ids" {
  description = "Dashboard resource IDs keyed by dashboard key."
  value       = module.gcp_cloud_monitoring.dashboard_ids
}

output "common_labels" {
  description = "Common governance labels applied by this module call."
  value       = module.gcp_cloud_monitoring.common_labels
}
