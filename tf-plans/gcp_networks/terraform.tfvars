# terraform.tfvars
# ---------------------------------------------------------------------------
# Example values for the GCP VPC deployment plan.
# Adjust project_id, names, and labels to match your environment.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Provider region
# ---------------------------------------------------------------------------
region = "us-central1"

# ---------------------------------------------------------------------------
# Default project ID — used for all networks unless overridden per entry.
# ---------------------------------------------------------------------------
project_id = "main-project-492903"

# ---------------------------------------------------------------------------
# Common labels applied to all networks.
# ---------------------------------------------------------------------------
labels = {
  owner       = "platform-team"
  environment = "shared"
}

# ---------------------------------------------------------------------------
# Networks to create.
# Each entry maps to one google_compute_network resource.
# ---------------------------------------------------------------------------
networks = [
  {
    # Shared VPC host network with global routing for cross-region services.
    key             = "platform-shared"
    name            = "platform-shared-vpc"
    description     = "Shared VPC host network for platform services"
    routing_mode    = "GLOBAL"
    mtu             = 1460 # This means VMs must use 1460 MTU or lower to avoid fragmentation; recommended for all but VLAN attachments.
    shared_vpc_host = true
    labels = {
      tier = "platform"
    }
  },
  {
    # Standard development network with regional routing.
    key          = "apps-dev"
    name         = "apps-dev-vpc"
    description  = "Development network for application teams"
    routing_mode = "REGIONAL"
    labels = {
      tier        = "dev"
      cost_center = "engineering"
    }
  }
]
