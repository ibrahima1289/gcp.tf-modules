locals {
  # Creation date passed into the tags merge in main.tf.
  created_date = formatdate("YYYY-MM-DD", timestamp())
}
