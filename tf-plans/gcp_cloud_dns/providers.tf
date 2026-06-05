# providers.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Optional remote backend (GCS): uncomment and set real values.
  # backend "gcs" {
  #   bucket = "my-terraform-state-bucket"
  #   prefix = "gcp-cloud-dns"
  # }
}

# ---------------------------------------------------------------------------
# Provider credentials are inherited from Application Default Credentials.
# Project is pinned to the default project for plan-level visibility.
# ---------------------------------------------------------------------------
provider "google" {
  project = var.project_id
  region  = var.region
}
