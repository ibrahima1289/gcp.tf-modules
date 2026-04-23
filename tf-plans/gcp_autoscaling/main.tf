# ---------------------------------------------------------------------------
# Step 0a: Instance Templates
# Defines the VM boot configuration for each Managed Instance Group.
# Templates are versioned by name; update the name to trigger a rolling
# replacement of MIG instances.
# ---------------------------------------------------------------------------
resource "google_compute_instance_template" "mig_template" {
  for_each = { for t in var.instance_templates : t.key => t if t.create }

  project      = var.project_id
  name         = each.value.name
  machine_type = each.value.machine_type
  tags         = each.value.tags

  disk {
    source_image = each.value.image
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = each.value.network
    subnetwork = trimspace(each.value.subnetwork) != "" ? each.value.subnetwork : null
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Step 0b: Regional Managed Instance Groups
# Creates the regional MIG that the autoscaler will target. The MIG must
# exist before the autoscaler can be created — Terraform's dependency graph
# ensures this via the template reference below.
# ---------------------------------------------------------------------------
resource "google_compute_region_instance_group_manager" "regional_mig" {
  for_each = { for m in var.regional_migs : m.key => m if m.create }

  project            = var.project_id
  name               = each.value.name
  region             = trimspace(each.value.region) != "" ? each.value.region : var.region
  base_instance_name = each.value.base_instance_name
  target_size        = each.value.target_size

  version {
    instance_template = google_compute_instance_template.mig_template[each.value.template_key].id
  }

  depends_on = [google_compute_instance_template.mig_template]
}

# ---------------------------------------------------------------------------
# Step 0c: Resolve autoscaler targets
# Build a lookup map from autoscaler_key → MIG id for any MIG that declares
# an autoscaler_key. Autoscalers whose key appears in this map have their
# target replaced with the resource id; all others keep the value from
# var.autoscalers (e.g. a pre-existing MIG self-link).
# ---------------------------------------------------------------------------
locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # autoscaler_key → id of the regional MIG that declared it
  mig_id_by_autoscaler_key = {
    for m in var.regional_migs : m.autoscaler_key => google_compute_region_instance_group_manager.regional_mig[m.key].id
    if m.create && trimspace(m.autoscaler_key) != ""
  }

  # Patch the target for any autoscaler whose key matches a newly created MIG
  autoscalers_resolved = [
    for a in var.autoscalers : merge(a, {
      target = lookup(local.mig_id_by_autoscaler_key, a.key, a.target)
    })
  ]
}

# ---------------------------------------------------------------------------
# Step 1: Autoscalers
# Pass the resolved autoscaler list (with MIG ids injected) to the module.
# ---------------------------------------------------------------------------
module "gcp_autoscaling" {
  source      = "../../modules/networking/gcp_autoscaling"
  project_id  = var.project_id
  region      = var.region
  autoscalers = local.autoscalers_resolved

  # Merge caller-supplied tags with generated metadata
  tags = merge(
    var.tags,
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  depends_on = [google_compute_region_instance_group_manager.regional_mig]
}
