# providers.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Optional remote backend (GCS): uncomment and set real values before first apply.
  # backend "gcs" {
  #   bucket = "my-terraform-state-bucket"
  #   prefix = "gcp-cloud-storage"
  # }
}

# ---------------------------------------------------------------------------
# Provider credentials and default region are set in the wrapper.
# ---------------------------------------------------------------------------
provider "google" {
  region = var.region
}
