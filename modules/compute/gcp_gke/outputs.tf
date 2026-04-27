# ---------------------------------------------------------------------------
# Cluster identity outputs — merged across standard and autopilot clusters.
# ---------------------------------------------------------------------------

output "cluster_names" {
  description = "Cluster resource names keyed by cluster.key."
  value = merge(
    { for k, c in google_container_cluster.standard : k => c.name },
    { for k, c in google_container_cluster.autopilot : k => c.name }
  )
}

output "cluster_ids" {
  description = "Cluster resource IDs keyed by cluster.key."
  value = merge(
    { for k, c in google_container_cluster.standard : k => c.id },
    { for k, c in google_container_cluster.autopilot : k => c.id }
  )
}

output "cluster_endpoints" {
  description = "Private or public HTTPS endpoint of each cluster's Kubernetes API server, keyed by cluster.key."
  sensitive   = true
  value = merge(
    { for k, c in google_container_cluster.standard : k => c.endpoint },
    { for k, c in google_container_cluster.autopilot : k => c.endpoint }
  )
}

output "cluster_ca_certificates" {
  description = "Base64-encoded public certificate of each cluster's CA, keyed by cluster.key. Use with kubectl / kubeconfig."
  sensitive   = true
  value = merge(
    { for k, c in google_container_cluster.standard : k => c.master_auth[0].cluster_ca_certificate },
    { for k, c in google_container_cluster.autopilot : k => c.master_auth[0].cluster_ca_certificate }
  )
}

output "cluster_locations" {
  description = "Effective location (region or zone) of each cluster, keyed by cluster.key."
  value = merge(
    { for k, c in google_container_cluster.standard : k => c.location },
    { for k, c in google_container_cluster.autopilot : k => c.location }
  )
}

# ---------------------------------------------------------------------------
# Node pool outputs (standard clusters only)
# ---------------------------------------------------------------------------

output "node_pool_ids" {
  description = "Node pool resource IDs keyed by '<cluster_key>/<pool_key>'."
  value       = { for k, np in google_container_node_pool.pools : k => np.id }
}

output "node_pool_instance_group_urls" {
  description = "Instance group self-links for each node pool, keyed by '<cluster_key>/<pool_key>'."
  value       = { for k, np in google_container_node_pool.pools : k => np.managed_instance_group_urls }
}

# ---------------------------------------------------------------------------
# Governance metadata
# ---------------------------------------------------------------------------

output "common_labels" {
  description = "Merged governance labels applied to all resources (managed_by, created_date, + caller tags)."
  value       = local.common_labels
}
