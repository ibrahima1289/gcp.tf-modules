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
  #   prefix = "gcp-cloud-nat"
  # }
}

# ---------------------------------------------------------------------------
# Provider credentials and region ownership live in the wrapper.
# ---------------------------------------------------------------------------
provider "google" {
  region = var.region
}
