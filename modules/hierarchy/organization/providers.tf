terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

# Google provider — credentials sourced from Application Default Credentials
# (gcloud auth application-default login) or Workload Identity Federation.
# Organization-level resources are global; region is set for provider consistency.
provider "google" {
  region = var.region
}
