# locals.tf

locals {
  # Timestamp captured at plan time and injected into the created_date label.
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
