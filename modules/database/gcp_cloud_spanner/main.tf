# Step 1: Create Spanner instances that use processing units.
resource "google_spanner_instance" "processing_units" {
  for_each = local.instances_processing_units_fixed

  project      = var.project_id
  name         = each.value.name
  config       = each.value.config
  display_name = each.value.display_name

  # Capacity model: granular compute scaling using processing units.
  processing_units = each.value.processing_units
  edition          = each.value.instance_edition
  force_destroy    = each.value.force_destroy
  labels           = each.value.labels

}

# Step 1a: Create processing-units instances with autoscaling enabled.
resource "google_spanner_instance" "processing_units_autoscaled" {
  for_each = local.instances_processing_units_autoscaled

  project      = var.project_id
  name         = each.value.name
  config       = each.value.config
  display_name = each.value.display_name

  edition       = each.value.instance_edition
  force_destroy = each.value.force_destroy
  labels        = each.value.labels

  autoscaling_config {
    autoscaling_limits {
      min_processing_units = each.value.autoscaling.min_processing_units
      max_processing_units = each.value.autoscaling.max_processing_units
    }

    autoscaling_targets {
      high_priority_cpu_utilization_percent = each.value.autoscaling.high_priority_cpu_utilization_percent
      storage_utilization_percent           = each.value.autoscaling.storage_utilization_percent
    }
  }
}

# Step 2: Create Spanner instances that use node-based capacity.
resource "google_spanner_instance" "nodes" {
  for_each = local.instances_nodes

  project      = var.project_id
  name         = each.value.name
  config       = each.value.config
  display_name = each.value.display_name

  # Capacity model: classic node-based sizing.
  num_nodes     = each.value.num_nodes
  edition       = each.value.instance_edition
  force_destroy = each.value.force_destroy
  labels        = each.value.labels
}

# Step 3: Create one or many databases across all enabled instances.
resource "google_spanner_database" "database" {
  for_each = local.databases_map

  project = var.project_id
  name    = each.value.name
  instance = try(
    google_spanner_instance.processing_units[each.value.instance_key].name,
    google_spanner_instance.processing_units_autoscaled[each.value.instance_key].name,
    google_spanner_instance.nodes[each.value.instance_key].name
  )

  database_dialect         = each.value.database_dialect
  ddl                      = each.value.ddl
  version_retention_period = each.value.version_retention_period
  deletion_protection      = each.value.deletion_protection
  enable_drop_protection   = each.value.enable_drop_protection

  # Optional CMEK for database encryption.
  dynamic "encryption_config" {
    for_each = trimspace(each.value.kms_key_name) != "" ? [1] : []
    content {
      kms_key_name = each.value.kms_key_name
    }
  }
}
