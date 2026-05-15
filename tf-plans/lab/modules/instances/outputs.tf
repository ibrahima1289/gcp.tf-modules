output "instance_1_id" {
  description = "The instance ID of tf-instance-1."
  value       = google_compute_instance.tf-instance-1.instance_id
}

output "instance_2_id" {
  description = "The instance ID of tf-instance-2."
  value       = google_compute_instance.tf-instance-2.instance_id
}
