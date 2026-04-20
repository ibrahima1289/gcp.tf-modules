locals {
  # Compute the creation timestamp once; passed into tags for all resources
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
