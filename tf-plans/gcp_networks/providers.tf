# providers.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Optional remote backend (GCS): uncomment and set real values before running init.
  # backend "gcs" {
  #   bucket = "my-terraform-state-bucket"
  #   prefix = "gcp-vpc"
  # }
}

# ---------------------------------------------------------------------------
# Provider owns the Google credentials and default region.
# No project is set here — each network in the list can target a different
# project; the module resolves project per resource.
# ---------------------------------------------------------------------------
provider "google" {
  region = var.region
}
