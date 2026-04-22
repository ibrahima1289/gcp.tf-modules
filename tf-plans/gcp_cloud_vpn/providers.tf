terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Uncomment to store state in GCS
  # backend "gcs" {
  #   bucket = "my-tf-state-bucket"
  #   prefix = "gcp_cloud_vpn"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
