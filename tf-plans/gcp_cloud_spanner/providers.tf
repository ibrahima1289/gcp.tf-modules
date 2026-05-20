terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

# Configure provider context for this deployment plan.
provider "google" {
  project = var.project_id
  region  = var.region
}
