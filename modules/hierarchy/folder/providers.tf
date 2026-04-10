terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

# Region is required for provider configuration even for global folder resources.
provider "google" {
  region = var.region
}
