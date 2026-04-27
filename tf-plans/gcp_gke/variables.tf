variable "project_id" {
  description = "GCP project ID where all GKE clusters are created."
  type        = string
}

variable "region" {
  description = "Default GCP region for clusters whose location field is left empty."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels applied to all resources."
  type        = map(string)
  default     = {}
}

variable "clusters" {
  description = "List of GKE cluster definitions — standard or autopilot, with optional node pools."
  type = list(object({
    key       = string
    create    = optional(bool, true)
    name      = string
    location  = optional(string, "")
    autopilot = optional(bool, false)

    network    = optional(string, "default")
    subnetwork = optional(string, "default")

    cluster_secondary_range_name  = optional(string, "")
    services_secondary_range_name = optional(string, "")
    pods_ipv4_cidr_block          = optional(string, "")
    services_ipv4_cidr_block      = optional(string, "")

    enable_private_nodes    = optional(bool, false)
    enable_private_endpoint = optional(bool, false)
    master_ipv4_cidr_block  = optional(string, "172.16.0.0/28")

    master_authorized_networks = optional(list(object({
      cidr_block   = string
      display_name = optional(string, "")
    })), [])

    release_channel    = optional(string, "REGULAR")
    min_master_version = optional(string, "")

    workload_identity_pool      = optional(string, "")
    enable_binary_authorization = optional(bool, false)

    logging_service           = optional(string, "logging.googleapis.com/kubernetes")
    monitoring_service        = optional(string, "monitoring.googleapis.com/kubernetes")
    enable_managed_prometheus = optional(bool, false)

    enable_network_policy      = optional(bool, false)
    enable_http_load_balancing = optional(bool, true)
    enable_hpa                 = optional(bool, true)

    maintenance_start_time = optional(string, "")
    deletion_protection    = optional(bool, false)

    node_pools = optional(list(object({
      key  = string
      name = string

      node_count     = optional(number, 1)
      autoscaling    = optional(bool, true)
      min_node_count = optional(number, 1)
      max_node_count = optional(number, 3)

      machine_type    = optional(string, "e2-medium")
      disk_size_gb    = optional(number, 100)
      disk_type       = optional(string, "pd-standard")
      image_type      = optional(string, "COS_CONTAINERD")
      spot            = optional(bool, false)
      service_account = optional(string, "default")

      oauth_scopes = optional(list(string), [
        "https://www.googleapis.com/auth/cloud-platform"
      ])

      labels = optional(map(string), {})
      tags   = optional(list(string), [])

      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])

      auto_repair     = optional(bool, true)
      auto_upgrade    = optional(bool, true)
      max_surge       = optional(number, 1)
      max_unavailable = optional(number, 0)
    })), [])
  }))
  default = []
}
