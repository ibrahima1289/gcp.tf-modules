terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

# Configure provider defaults for this module call.
provider "google" {
  project = var.project_id
  region  = var.region
}
