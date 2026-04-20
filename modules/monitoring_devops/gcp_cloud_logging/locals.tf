locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # Common labels applied to every labelable resource created by this module
  common_labels = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # Log buckets map — excludes create = false entries
  log_buckets_map = {
    for b in var.log_buckets : b.key => b
    if b.create
  }

  # Log sinks map — excludes create = false entries
  sinks_map = {
    for s in var.log_sinks : s.key => s
    if s.create
  }

  # Log exclusions map — excludes create = false entries
  exclusions_map = {
    for e in var.log_exclusions : e.key => e
    if e.create
  }

  # Log-based metrics map — excludes create = false entries
  metrics_map = {
    for m in var.log_metrics : m.key => m
    if m.create
  }
}
