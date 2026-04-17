# locals.tf

locals {
  # ---------------------------------------------------------------------------
  # Creation date stamped on every bucket as a label at apply time.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels merged into every bucket. Per-bucket labels are merged on top
  # so they can override or extend the common set.
  # ---------------------------------------------------------------------------
  common_tags = merge(
    {
      managed_by   = "terraform"
      created_date = local.created_date
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Resolve per-bucket overrides and produce a stable map keyed by bucket key.
  # All optional string fields are resolved here to avoid null propagation into
  # resource blocks.
  # ---------------------------------------------------------------------------
  buckets_map = {
    for b in var.buckets : b.key => merge(b, {
      # Resolve project and location to module defaults when not overridden.
      project_id = trimspace(b.project_id) != "" ? b.project_id : var.project_id
      location   = trimspace(b.location) != "" ? upper(b.location) : upper(var.region)

      # Merge common tags with per-bucket labels (per-bucket wins on conflict).
      labels = merge(local.common_tags, b.labels)
    })
  }

  # ---------------------------------------------------------------------------
  # Buckets that have access logging enabled (log_bucket != "").
  # ---------------------------------------------------------------------------
  buckets_with_logging = {
    for key, b in local.buckets_map : key => b
    if trimspace(b.log_bucket) != ""
  }

  # ---------------------------------------------------------------------------
  # Buckets that have website hosting configured (main page suffix set).
  # ---------------------------------------------------------------------------
  buckets_with_website = {
    for key, b in local.buckets_map : key => b
    if trimspace(b.website_main_page_suffix) != ""
  }

  # ---------------------------------------------------------------------------
  # Buckets that have CMEK encryption configured.
  # ---------------------------------------------------------------------------
  buckets_with_kms = {
    for key, b in local.buckets_map : key => b
    if trimspace(b.default_kms_key_name) != ""
  }
}
