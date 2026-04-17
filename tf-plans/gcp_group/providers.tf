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
  #   prefix = "gcp-group"
  # }
}

# ---------------------------------------------------------------------------
# Provider credentials are inherited from environment (ADC or GOOGLE_CREDENTIALS).
# Cloud Identity Groups are global — no region is required on the provider.
# ---------------------------------------------------------------------------
provider "google" {}
