terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Optional remote backend (GCS): uncomment and set real values.
  # ---------------------------------------------------------------------------
  # backend "gcs" {
  #   bucket = "my-terraform-state-bucket"
  #   prefix = "gcp-subnet"
  # }
}

# Region is required for provider configuration.
provider "google" {
  region = var.region
}
