variable "project_id" {
  description = "The Google Cloud Project ID."
  type        = string
  default     = "qwiklabs-gcp-02-6bfcd918f2d3"
}

variable "region" {
  description = "The default GCP region for resources."
  type        = string
  default     = "US"
}

variable "bucket_name" {
  description = "The name of the Google Cloud Storage bucket to create."
  type        = string
  default     = "tf-bucket-944292"
}