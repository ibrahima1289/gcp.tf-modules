output "cluster_names" {
  description = "Cluster resource names, keyed by cluster.key."
  value       = module.gcp_gke.cluster_names
}

output "cluster_ids" {
  description = "Cluster resource IDs, keyed by cluster.key."
  value       = module.gcp_gke.cluster_ids
}

output "cluster_endpoints" {
  description = "Kubernetes API server HTTPS endpoints, keyed by cluster.key."
  sensitive   = true
  value       = module.gcp_gke.cluster_endpoints
}

output "cluster_ca_certificates" {
  description = "Base64-encoded cluster CA certificates for kubeconfig, keyed by cluster.key."
  sensitive   = true
  value       = module.gcp_gke.cluster_ca_certificates
}

output "cluster_locations" {
  description = "Effective cluster locations (region or zone), keyed by cluster.key."
  value       = module.gcp_gke.cluster_locations
}

output "node_pool_ids" {
  description = "Node pool resource IDs, keyed by '<cluster_key>/<pool_key>'."
  value       = module.gcp_gke.node_pool_ids
}

output "node_pool_instance_group_urls" {
  description = "Instance group self-links per node pool."
  value       = module.gcp_gke.node_pool_instance_group_urls
}

output "common_labels" {
  description = "Merged governance labels applied to all resources."
  value       = module.gcp_gke.common_labels
}
