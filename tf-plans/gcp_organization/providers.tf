terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Remote backend — update the bucket and prefix for your environment.
  # ---------------------------------------------------------------------------
  # backend "gcs" {
  #   bucket = "my-org-terraform-state"
  #   prefix = "gcp-organization"
  # }
}

provider "google" {
  region = var.region
}
