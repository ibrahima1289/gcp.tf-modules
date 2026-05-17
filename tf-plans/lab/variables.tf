variable "project_id" {
  description = "The Google Cloud Project ID."
  type        = string
  default     = "qwiklabs-gcp-01-1d8990dbbb2a"
}

variable "region" {
  description = "The default GCP region for resources."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "The default GCP zone for resources."
  type        = string
  default     = "us-east1-c"
}
