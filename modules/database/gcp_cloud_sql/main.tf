resource "google_sql_database_instance" "instance" {
  for_each = local.instances_map # excludes create = false entries

  project             = var.project_id
  name                = each.value.name
  database_version    = each.value.database_version # MYSQL_8_0 | POSTGRES_15 | SQLSERVER_2022_STANDARD etc.
  region              = each.value.region
  deletion_protection = each.value.deletion_protection # set false before destroy

  settings {
    tier                  = each.value.tier              # machine type e.g. db-n1-standard-2
    edition               = each.value.edition           # ENTERPRISE | ENTERPRISE_PLUS
    availability_type     = each.value.availability_type # ZONAL | REGIONAL (HA)
    disk_size             = each.value.disk_size
    disk_type             = each.value.disk_type
    disk_autoresize       = each.value.disk_autoresize
    disk_autoresize_limit = each.value.disk_autoresize_limit # 0 = unlimited
    user_labels           = each.value.labels

    backup_configuration {
      enabled                        = each.value.backup_enabled
      binary_log_enabled             = each.value.binary_log_enabled             # MySQL only
      point_in_time_recovery_enabled = each.value.point_in_time_recovery_enabled # Postgres / SQL Server
      start_time                     = each.value.backup_start_time
      transaction_log_retention_days = each.value.transaction_log_retention_days
      location                       = trimspace(each.value.backup_location) != "" ? each.value.backup_location : null

      backup_retention_settings {
        retained_backups = each.value.retained_backups
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = each.value.ipv4_enabled
      ssl_mode        = each.value.ssl_mode
      private_network = trimspace(each.value.private_network) != "" ? each.value.private_network : null

      dynamic "authorized_networks" {
        for_each = each.value.authorized_networks # public IP allowlist entries
        content {
          name            = authorized_networks.value.name
          value           = authorized_networks.value.value
          expiration_time = trimspace(authorized_networks.value.expiration_time) != "" ? authorized_networks.value.expiration_time : null
        }
      }
    }

    maintenance_window {
      day          = each.value.maintenance_window_day          # 1=Mon … 7=Sun
      hour         = each.value.maintenance_window_hour         # UTC
      update_track = each.value.maintenance_window_update_track # canary | stable
    }

    dynamic "insights_config" {
      for_each = each.value.insights_config_enabled ? [1] : [] # Query Insights
      content {
        query_insights_enabled  = true
        query_string_length     = each.value.query_string_length
        record_application_tags = each.value.record_application_tags
        record_client_address   = each.value.record_client_address
        query_plans_per_minute  = each.value.query_plans_per_minute
      }
    }

    dynamic "database_flags" {
      for_each = each.value.database_flags # engine-specific flags e.g. max_connections
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
  }
}

resource "google_sql_database" "database" {
  for_each = local.databases_map # keyed "<instance_key>--<db_name>"

  project   = var.project_id
  instance  = google_sql_database_instance.instance[each.value.instance_key].name
  name      = each.value.name
  charset   = trimspace(each.value.charset) != "" ? each.value.charset : null # null = engine default
  collation = trimspace(each.value.collation) != "" ? each.value.collation : null
}

resource "google_sql_user" "user" {
  for_each = local.users_map # keyed "<instance_key>--<user_name>"

  project  = var.project_id
  instance = google_sql_database_instance.instance[each.value.instance_key].name
  name     = each.value.name
  password = trimspace(each.value.password) != "" ? each.value.password : null # null skips password (IAM users)
  host     = each.value.type == "BUILT_IN" ? each.value.host : null            # host applies to MySQL built-in users only
  type     = each.value.type                                                   # BUILT_IN | CLOUD_IAM_USER | CLOUD_IAM_SERVICE_ACCOUNT | CLOUD_IAM_GROUP
}
