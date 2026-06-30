# ── AlloyDB Cluster ────────────────────────────────────────────────────────────
# Creates one AlloyDB cluster per active entry. The cluster holds instances and
# manages continuous backups, PITR, automated backups, network peering, and CMEK.
resource "google_alloydb_cluster" "cluster" {
  for_each = local.clusters_map

  project    = var.project_id
  cluster_id = each.value.name
  location   = each.value.region

  # VPC network — AlloyDB requires Private Service Access (PSA); no public IP at cluster level
  network_config {
    network = each.value.network
    # allocated_ip_range omitted — AlloyDB selects a PSA range automatically
  }

  # Cluster type: PRIMARY (standalone) or SECONDARY (cross-region replica)
  cluster_type = each.value.cluster_type

  # Automated backup policy: scheduled backups with count- or time-based retention
  automated_backup_policy {
    enabled       = each.value.automated_backup_enabled
    location      = trimspace(each.value.automated_backup_location) != "" ? each.value.automated_backup_location : each.value.region
    backup_window = "3600s" # 1-hour backup window starting at start_times below

    weekly_schedule {
      # At least one day is required; defaults to MONDAY
      days_of_week = each.value.automated_backup_days_of_week
      start_times {
        hours   = tonumber(split(":", each.value.automated_backup_start_time)[0])
        minutes = tonumber(split(":", each.value.automated_backup_start_time)[1])
        seconds = 0
        nanos   = 0
      }
    }

    # Retention policy: use count-based unless retention_days > 0
    dynamic "quantity_based_retention" {
      for_each = each.value.automated_backup_retention_days == 0 ? [1] : []
      content {
        count = each.value.automated_backup_retention_count
      }
    }

    dynamic "time_based_retention" {
      for_each = each.value.automated_backup_retention_days > 0 ? [1] : []
      content {
        retention_period = "${each.value.automated_backup_retention_days * 86400}s" # days → seconds
      }
    }
  }

  # Continuous backup (PITR) — enables point-in-time recovery up to N days back
  continuous_backup_config {
    enabled              = each.value.continuous_backup_enabled
    recovery_window_days = each.value.continuous_backup_recovery_window
  }

  # CMEK: use customer-managed KMS key when supplied; otherwise Google-managed key
  dynamic "encryption_config" {
    for_each = trimspace(each.value.kms_key_name) != "" ? [1] : []
    content {
      kms_key_name = each.value.kms_key_name
    }
  }

  # Initial database user created at cluster provisioning time
  initial_user {
    user     = each.value.initial_user
    password = each.value.initial_password
  }

  # Maintenance window — schedule major maintenance for low-traffic periods
  maintenance_update_policy {
    maintenance_windows {
      day = each.value.maintenance_window_day
      start_time {
        hours   = each.value.maintenance_window_hour
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  labels              = each.value.labels
  deletion_protection = each.value.deletion_protection
}

# ── AlloyDB Primary Instance ───────────────────────────────────────────────────
# Each cluster has exactly one primary (read/write) instance. REGIONAL availability
# provides automatic zone-level failover without a separate standby VM.
resource "google_alloydb_instance" "primary" {
  for_each = local.clusters_map

  cluster       = google_alloydb_cluster.cluster[each.key].name
  instance_id   = "${each.value.name}-${try(each.value.primary.instance_id, "primary")}"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = try(each.value.primary.cpu_count, 2)
  }

  # REGIONAL = automatic HA failover; ZONAL = single-zone (lower cost)
  availability_type = try(each.value.primary.availability_type, "REGIONAL")

  # Engine-level flags (e.g. max_connections, log_min_duration_statement)
  database_flags = try(each.value.primary.database_flags, {})

  # Require AlloyDB Auth Proxy for all connections / SSL enforcement mode
  client_connection_config {
    require_connectors = try(each.value.primary.require_connectors, false)
    ssl_config {
      ssl_mode = try(each.value.primary.ssl_mode, "ENCRYPTED_ONLY")
    }
  }

  # Columnar engine: in-memory columnar cache for accelerated analytics queries
  query_insights_config {
    query_string_length     = 1024
    record_application_tags = false
    record_client_address   = false
    query_plans_per_minute  = 5
  }

  depends_on = [google_alloydb_cluster.cluster]
}

# ── AlloyDB Read Pool Instances ────────────────────────────────────────────────
# Read pool instances scale out read-heavy workloads. Traffic is load-balanced
# automatically across all nodes within a pool. Each pool is a separate resource
# keyed by "<cluster_key>--<instance_id>" for stable Terraform state.
resource "google_alloydb_instance" "read_pool" {
  for_each = local.read_pools_map

  cluster       = google_alloydb_cluster.cluster[each.value.cluster_key].name
  instance_id   = "${local.clusters_map[each.value.cluster_key].name}-${each.value.instance_id}"
  instance_type = "READ_POOL"

  machine_config {
    cpu_count = each.value.cpu_count
  }

  # node_count controls horizontal read-pool scaling (number of parallel read nodes)
  read_pool_config {
    node_count = each.value.node_count
  }

  database_flags = each.value.database_flags

  client_connection_config {
    require_connectors = each.value.require_connectors
    ssl_config {
      ssl_mode = each.value.ssl_mode
    }
  }

  # Read pools must be created after the primary is ready
  depends_on = [google_alloydb_instance.primary]
}
