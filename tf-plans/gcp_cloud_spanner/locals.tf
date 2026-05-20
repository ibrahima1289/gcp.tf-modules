locals {
  # Generated once per run and merged into governance tags.
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
