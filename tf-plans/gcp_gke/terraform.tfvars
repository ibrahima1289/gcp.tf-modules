project_id = "main-project-492903"
region     = "us-central1"

tags = {
  env     = "dev"
  team    = "platform"
  owner   = "infra-team"
  project = "main-project-492903"
}

clusters = [
  # ── Standard regional cluster — production web workloads ────────────────
  # Regional (3-zone HA) with private nodes, Workload Identity, and two pools.
  # Set create = true once the VPC, subnetwork, and secondary ranges exist.
  {
    key       = "prod-web"
    create    = false
    name      = "prod-web-cluster"
    location  = "us-central1" # regional = 3-zone HA
    autopilot = false

    network    = "projects/my-gcp-project/global/networks/prod-vpc"
    subnetwork = "projects/my-gcp-project/regions/us-central1/subnetworks/prod-gke"

    # Secondary ranges that must exist on the subnetwork before creation.
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"

    # Private cluster — nodes have internal IPs only; master behind VPN/Cloud NAT.
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
    master_authorized_networks = [
      {
        cidr_block   = "10.0.0.0/8",
        display_name = "corp-vpn"
      },
      {
        cidr_block   = "35.235.240.0/20",
        display_name = "cloud-shell"
      }
    ]

    release_channel           = "REGULAR" # can be overridden to "STABLE" or "RAPID" for different upgrade cadences
    workload_identity_pool    = "my-gcp-project.svc.id.goog"
    enable_managed_prometheus = true
    enable_network_policy     = true
    maintenance_start_time    = "03:00"
    deletion_protection       = false # set true in production

    node_pools = [
      # General-purpose pool — web servers and APIs.
      {
        key            = "general"
        name           = "general-pool"
        machine_type   = "e2-standard-4"
        disk_size_gb   = 100
        disk_type      = "pd-balanced"
        autoscaling    = true
        min_node_count = 2
        max_node_count = 10
        auto_repair    = true
        auto_upgrade   = true
        labels         = { workload = "general" }
      },
      # Spot pool — batch jobs and fault-tolerant workloads at lower cost.
      {
        key            = "spot-batch"
        name           = "spot-batch-pool"
        machine_type   = "e2-standard-2"
        spot           = true
        autoscaling    = true
        min_node_count = 0
        max_node_count = 20
        labels         = { workload = "batch" }
        taints = [
          {
            key    = "cloud.google.com/gke-spot"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        ]
      }
    ]
  },

  # ── Autopilot cluster — dev / staging environment ───────────────────────
  # Google manages all nodes and scaling. No node_pools needed.
  {
    key       = "dev-autopilot"
    create    = true
    name      = "dev-autopilot-cluster"
    autopilot = true
    location  = "us-east1"

    network    = "default"
    subnetwork = "default"

    release_channel        = "REGULAR" # Can also be "STABLE" or "RAPID".
    workload_identity_pool = "main-project-492903.svc.id.goog"
    deletion_protection    = false

    # node_pools is ignored for autopilot clusters.
    node_pools = []
  },

  # ── Zonal standard cluster — GPU workloads (single zone) ─────────────────
  {
    key       = "gpu-zonal"
    create    = false
    name      = "gpu-zonal-cluster"
    autopilot = false
    location  = "us-central1-a" # zonal — required for GPU node pools

    network    = "projects/my-gcp-project/global/networks/prod-vpc"
    subnetwork = "projects/my-gcp-project/regions/us-central1/subnetworks/prod-gke"

    enable_private_nodes   = true
    master_ipv4_cidr_block = "172.16.1.0/28"

    release_channel = "STABLE"

    node_pools = [
      {
        key            = "gpu"
        name           = "gpu-pool"
        machine_type   = "n1-standard-4" # GPU VMs require N1 family
        disk_size_gb   = 200
        disk_type      = "pd-ssd"
        autoscaling    = true
        min_node_count = 0
        max_node_count = 4
        taints = [
          {
            key    = "nvidia.com/gpu"
            value  = "present"
            effect = "NO_SCHEDULE"
          }
        ]
        labels = { hardware = "gpu" }
      }
    ]
  }
]
