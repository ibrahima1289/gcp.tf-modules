# ===========================================================================
# Step 1: Standard GKE clusters (Terraform manages node pools separately)
# remove_default_node_pool = true deletes the default pool immediately so all
# node pools are managed as separate google_container_node_pool resources.
# ===========================================================================
resource "google_container_cluster" "standard" {
  for_each = { for c in var.clusters : c.key => c if c.create && !c.autopilot }

  project  = var.project_id
  name     = each.value.name
  location = trimspace(each.value.location) != "" ? each.value.location : var.region

  # Remove the single-node bootstrap pool — actual pools are in Step 3.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Networking — subnetwork must be in the same region as the cluster.
  network    = each.value.network
  subnetwork = each.value.subnetwork

  # VPC-native (alias IP) networking — strongly recommended for GKE.
  # Provide secondary range names OR let GKE auto-allocate CIDR blocks.
  ip_allocation_policy {
    cluster_secondary_range_name  = trimspace(each.value.cluster_secondary_range_name) != "" ? each.value.cluster_secondary_range_name : null
    services_secondary_range_name = trimspace(each.value.services_secondary_range_name) != "" ? each.value.services_secondary_range_name : null
    cluster_ipv4_cidr_block       = trimspace(each.value.cluster_secondary_range_name) == "" ? each.value.pods_ipv4_cidr_block : null
    services_ipv4_cidr_block      = trimspace(each.value.services_secondary_range_name) == "" ? each.value.services_ipv4_cidr_block : null
  }

  # Private cluster: nodes and/or control plane only reachable via private IPs.
  dynamic "private_cluster_config" {
    for_each = each.value.enable_private_nodes ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = each.value.enable_private_endpoint
      master_ipv4_cidr_block  = each.value.master_ipv4_cidr_block
    }
  }

  # Master authorized networks — restrict which CIDRs can reach the API server.
  dynamic "master_authorized_networks_config" {
    for_each = length(each.value.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = each.value.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Release channel controls automatic Kubernetes version upgrades.
  release_channel {
    channel = each.value.release_channel
  }

  # Explicit version only used when release_channel = UNSPECIFIED.
  min_master_version = trimspace(each.value.min_master_version) != "" ? each.value.min_master_version : null

  # Workload Identity maps GCP service accounts to Kubernetes service accounts.
  dynamic "workload_identity_config" {
    for_each = trimspace(each.value.workload_identity_pool) != "" ? [1] : []
    content {
      workload_pool = each.value.workload_identity_pool
    }
  }

  # Logging and monitoring — use GKE-managed collection endpoints.
  logging_service    = each.value.logging_service
  monitoring_service = each.value.monitoring_service

  # Managed Prometheus: enable GKE Managed Collection for Prometheus metrics.
  dynamic "monitoring_config" {
    for_each = each.value.enable_managed_prometheus ? [1] : []
    content {
      managed_prometheus {
        enabled = true
      }
    }
  }

  # Network policy (Calico) — enables PodNetworkPolicy enforcement.
  dynamic "network_policy" {
    for_each = each.value.enable_network_policy ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  # Cluster add-ons: HTTP LB (required for Ingress), HPA, and network policy.
  addons_config {
    http_load_balancing {
      disabled = !each.value.enable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !each.value.enable_hpa
    }
    network_policy_config {
      disabled = !each.value.enable_network_policy
    }
  }

  # Binary Authorization enforces image signing policies at deploy time.
  dynamic "binary_authorization" {
    for_each = each.value.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Maintenance window: schedule disruptive upgrades to off-peak hours.
  dynamic "maintenance_policy" {
    for_each = trimspace(each.value.maintenance_start_time) != "" ? [1] : []
    content {
      daily_maintenance_window {
        start_time = each.value.maintenance_start_time
      }
    }
  }

  # Governance labels propagated to all cluster resources.
  resource_labels = local.common_labels

  # Allow Terraform to destroy the cluster (set true in production to prevent accidents).
  deletion_protection = each.value.deletion_protection
}

# ===========================================================================
# Step 2: Autopilot GKE clusters
# Google manages all node pools, bin-packing, and OS patching.
# Cannot set remove_default_node_pool or initial_node_count in Autopilot mode.
# ===========================================================================
resource "google_container_cluster" "autopilot" {
  for_each = { for c in var.clusters : c.key => c if c.create && c.autopilot }

  project  = var.project_id
  name     = each.value.name
  location = trimspace(each.value.location) != "" ? each.value.location : var.region

  # Autopilot mode — enables fully managed node provisioning by Google.
  enable_autopilot = true

  network    = each.value.network
  subnetwork = each.value.subnetwork

  ip_allocation_policy {
    cluster_secondary_range_name  = trimspace(each.value.cluster_secondary_range_name) != "" ? each.value.cluster_secondary_range_name : null
    services_secondary_range_name = trimspace(each.value.services_secondary_range_name) != "" ? each.value.services_secondary_range_name : null
    cluster_ipv4_cidr_block       = trimspace(each.value.cluster_secondary_range_name) == "" ? each.value.pods_ipv4_cidr_block : null
    services_ipv4_cidr_block      = trimspace(each.value.services_secondary_range_name) == "" ? each.value.services_ipv4_cidr_block : null
  }

  dynamic "private_cluster_config" {
    for_each = each.value.enable_private_nodes ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = each.value.enable_private_endpoint
      master_ipv4_cidr_block  = each.value.master_ipv4_cidr_block
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(each.value.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = each.value.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  release_channel {
    channel = each.value.release_channel
  }

  dynamic "workload_identity_config" {
    for_each = trimspace(each.value.workload_identity_pool) != "" ? [1] : []
    content {
      workload_pool = each.value.workload_identity_pool
    }
  }

  logging_service    = each.value.logging_service
  monitoring_service = each.value.monitoring_service

  dynamic "maintenance_policy" {
    for_each = trimspace(each.value.maintenance_start_time) != "" ? [1] : []
    content {
      daily_maintenance_window {
        start_time = each.value.maintenance_start_time
      }
    }
  }

  resource_labels     = local.common_labels
  deletion_protection = each.value.deletion_protection
}

# ===========================================================================
# Step 3: Node pools for standard clusters only
# Each node pool is a separate resource for independent scaling and upgrades.
# Autopilot clusters are skipped — Google manages nodes automatically.
# Node pool keys: "<cluster_key>/<pool_key>" for stable Terraform state.
# ===========================================================================
resource "google_container_node_pool" "pools" {
  for_each = local.node_pools_flat

  project  = var.project_id
  cluster  = google_container_cluster.standard[each.value.cluster_key].name
  location = each.value.location
  name     = each.value.name

  # Autoscaling or fixed node count — mutually exclusive.
  dynamic "autoscaling" {
    for_each = each.value.autoscaling ? [1] : []
    content {
      min_node_count = each.value.min_node_count
      max_node_count = each.value.max_node_count
    }
  }

  # Fixed node count used when autoscaling = false.
  node_count = each.value.autoscaling ? null : each.value.node_count

  # Node VM configuration: machine type, disk, OS image, and Spot flag.
  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    image_type      = each.value.image_type
    spot            = each.value.spot
    service_account = each.value.service_account
    oauth_scopes    = each.value.oauth_scopes
    labels          = each.value.labels
    tags            = each.value.tags

    # Workload Identity on nodes: expose GKE metadata server to pods.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Taints isolate workloads to specific node pools (e.g. GPU nodes, Spot-only).
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  # Auto-repair restarts unhealthy nodes; auto-upgrade keeps nodes on the latest minor version.
  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  # Surge upgrades control how many extra / unavailable nodes are allowed during rollout.
  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }
}
