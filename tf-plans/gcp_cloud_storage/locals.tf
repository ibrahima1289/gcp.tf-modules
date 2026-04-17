# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped as a label on every bucket at apply time.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
