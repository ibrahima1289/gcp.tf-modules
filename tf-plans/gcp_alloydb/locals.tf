locals {
  # Stamp the current date for the created_date governance label
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
