# terraform.tfvars

# ---------------------------------------------------------------------------
# Default placement
# ---------------------------------------------------------------------------
project_id = "my-platform-project"
region     = "us-central1"

# ---------------------------------------------------------------------------
# Common metadata tags
# ---------------------------------------------------------------------------
tags = {
  owner       = "platform-team"
  environment = "shared"
}

# ---------------------------------------------------------------------------
# One or many NAT definitions
# ---------------------------------------------------------------------------
nats = [
  {
    key           = "nat-auto-primary"
    name          = "nat-auto-primary"
    create_router = true
    router_name   = "nat-auto-primary-router"
    network       = "projects/my-platform-project/global/networks/platform-shared-vpc"

    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    log_config_enable = true
    log_config_filter = "ERRORS_ONLY"
  },
  {
    key    = "nat-manual-apps"
    name   = "nat-manual-apps"
    router = "existing-router-central"

    nat_ip_allocate_option = "MANUAL_ONLY"
    nat_ips = [
      "projects/my-platform-project/regions/us-central1/addresses/nat-ip-01"
    ]

    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetworks = [
      {
        name                    = "projects/my-platform-project/regions/us-central1/subnetworks/apps-central"
        source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
      }
    ]
  }
]
