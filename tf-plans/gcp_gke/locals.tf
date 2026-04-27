locals {
  # Creation date stamped on all clusters via the tags merge in main.tf.
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
