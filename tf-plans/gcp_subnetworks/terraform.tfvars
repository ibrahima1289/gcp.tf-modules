# ---------------------------------------------------------------------------
# Shared defaults for subnet creation.
# ---------------------------------------------------------------------------
project_id = "main-project-492903"
network    = "apps-dev-vpc"
region     = "us-central1"

labels = {
  environment = "shared"
  owner       = "network-team"
  repo        = "gcp-tf-modules"
}

# ---------------------------------------------------------------------------
# Create one or many subnets.
# ---------------------------------------------------------------------------
subnets = [
  {
    key                      = "apps-central"
    name                     = "apps-central"
    ip_cidr_range            = "10.10.0.0/24"
    private_ip_google_access = true
    secondary_ip_ranges = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.20.0.0/20"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.30.0.0/24"
      }
    ]
    log_config = {
      enabled              = true
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  },
  {
    key                      = "data-central"
    name                     = "data-central"
    ip_cidr_range            = "10.40.0.0/24"
    description              = "Subnet for data workloads"
    private_ip_google_access = false
  },
  {
    key                      = "legacy-east"
    name                     = "legacy-east"
    ip_cidr_range            = "10.50.0.0/24"
    region                   = "us-east1"
    private_ip_google_access = false

  }
]
