# ---------------------------------------------------------------------------
# Default project for all GKE resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID where all GKE clusters are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for clusters whose location field is left empty.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region. Used as the cluster location when location is not set on the entry."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels applied to all cluster resources.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date in locals."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# GKE cluster definitions.
# Each entry creates one google_container_cluster (standard or autopilot)
# and zero or more google_container_node_pool resources.
# ---------------------------------------------------------------------------
variable "clusters" {
  description = "List of GKE cluster definitions. Each entry creates one cluster plus its node pools (standard mode only)."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry in tfvars for reference.
    create = optional(bool, true)
    # GKE cluster resource name.
    name = string

    # Location: region for a regional cluster (3-zone HA), zone for a zonal cluster.
    # Defaults to var.region when empty.
    location = optional(string, "")

    # Autopilot: Google manages nodes, bin-packing, and scaling.
    # When true, node_pools entries are ignored.
    autopilot = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Networking
    # ---------------------------------------------------------------------------
    # VPC network self-link or name.
    network = optional(string, "default")
    # Subnetwork self-link or name. Must be in the same region as the cluster.
    subnetwork = optional(string, "default")

    # VPC-native (alias IP) pod and service CIDR configuration.
    # Provide secondary range names OR cidr blocks (not both).
    cluster_secondary_range_name  = optional(string, "") # existing secondary range for pods
    services_secondary_range_name = optional(string, "") # existing secondary range for services
    pods_ipv4_cidr_block          = optional(string, "") # auto-allocated pod CIDR
    services_ipv4_cidr_block      = optional(string, "") # auto-allocated service CIDR

    # ---------------------------------------------------------------------------
    # Private cluster
    # ---------------------------------------------------------------------------
    # Enable private nodes so worker nodes only have internal IP addresses.
    enable_private_nodes = optional(bool, false)
    # Enable private endpoint so the master API server is also private.
    enable_private_endpoint = optional(bool, false)
    # /28 CIDR block for the master node IP range (must not overlap VPC ranges).
    master_ipv4_cidr_block = optional(string, "172.16.0.0/28")

    # CIDR blocks allowed to reach the Kubernetes API server.
    master_authorized_networks = optional(list(object({
      cidr_block   = string
      display_name = optional(string, "")
    })), [])

    # ---------------------------------------------------------------------------
    # Versioning
    # ---------------------------------------------------------------------------
    # Release channel for automatic version upgrades: RAPID, REGULAR, STABLE, or UNSPECIFIED.
    release_channel = optional(string, "REGULAR")
    # Explicit Kubernetes version — only respected when release_channel = UNSPECIFIED.
    min_master_version = optional(string, "")

    # ---------------------------------------------------------------------------
    # Security
    # ---------------------------------------------------------------------------
    # Workload Identity pool: "<project>.svc.id.goog" enables Workload Identity.
    # Leave empty to disable Workload Identity.
    workload_identity_pool = optional(string, "")
    # Enforce image signing policies at pod admission (requires Binary Authorization policy).
    enable_binary_authorization = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Logging and monitoring
    # ---------------------------------------------------------------------------
    logging_service    = optional(string, "logging.googleapis.com/kubernetes")
    monitoring_service = optional(string, "monitoring.googleapis.com/kubernetes")
    # Enable GKE Managed Collection (Managed Prometheus) for Prometheus metrics.
    enable_managed_prometheus = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Network policy
    # ---------------------------------------------------------------------------
    # Enable Calico network policy enforcement (PodNetworkPolicy).
    enable_network_policy = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Add-ons
    # ---------------------------------------------------------------------------
    # HTTP load balancing add-on — required for GKE Ingress objects.
    enable_http_load_balancing = optional(bool, true)
    # Horizontal Pod Autoscaler add-on.
    enable_hpa = optional(bool, true)

    # ---------------------------------------------------------------------------
    # Maintenance
    # ---------------------------------------------------------------------------
    # UTC start time for daily maintenance window (e.g. "03:00"). Leave empty to disable.
    maintenance_start_time = optional(string, "")

    # ---------------------------------------------------------------------------
    # Lifecycle
    # ---------------------------------------------------------------------------
    # Set true to prevent accidental terraform destroy in production.
    deletion_protection = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Node pools — only used when autopilot = false.
    # ---------------------------------------------------------------------------
    node_pools = optional(list(object({
      # Unique key within this cluster (combined with cluster key as map key).
      key = string
      # Node pool resource name.
      name = string

      # Node count when autoscaling is disabled.
      node_count = optional(number, 1)

      # Cluster autoscaler: scale between min and max node count.
      autoscaling    = optional(bool, true)
      min_node_count = optional(number, 1)
      max_node_count = optional(number, 3)

      # VM configuration.
      machine_type = optional(string, "e2-medium")
      disk_size_gb = optional(number, 100)
      disk_type    = optional(string, "pd-standard")    # pd-standard, pd-ssd, pd-balanced
      image_type   = optional(string, "COS_CONTAINERD") # COS_CONTAINERD recommended

      # Spot VMs: lower cost for fault-tolerant batch or dev workloads.
      spot = optional(bool, false)

      # Service account for the node VMs.
      service_account = optional(string, "default")

      # OAuth scopes granted to the node service account.
      oauth_scopes = optional(list(string), [
        "https://www.googleapis.com/auth/cloud-platform"
      ])

      # Kubernetes node labels (visible to scheduler as node selectors).
      labels = optional(map(string), {})
      # GCE network tags applied to node VMs (used in firewall rules).
      tags = optional(list(string), [])

      # Taints isolate workloads — e.g. NoSchedule GPU nodes for GPU workloads only.
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string # NO_SCHEDULE, PREFER_NO_SCHEDULE, NO_EXECUTE
      })), [])

      # Node management: auto-repair and auto-upgrade for operational hygiene.
      auto_repair  = optional(bool, true)
      auto_upgrade = optional(bool, true)

      # Surge upgrade: max_surge extra nodes + max_unavailable nodes during rolling upgrade.
      max_surge       = optional(number, 1)
      max_unavailable = optional(number, 0)
    })), [])
  }))
  default = []

  validation {
    condition     = length(var.clusters) == length(distinct([for c in var.clusters : c.key]))
    error_message = "Each entry in clusters must have a unique key."
  }
}
