# main.tf

# ---------------------------------------------------------------------------
# Step 1: Create the App Engine application (singleton per project).
# location_id is permanent after first creation and cannot be changed.
# The application is looked up via data source if create = false.
# ---------------------------------------------------------------------------
resource "google_app_engine_application" "app" {
  count = var.application.create ? 1 : 0

  project        = var.project_id
  location_id    = var.application.location_id
  serving_status = var.application.serving_status
  database_type  = var.application.database_type

  # -------------------------------------------------------------------------
  # Step 2: Optional custom authentication domain for application users.
  # -------------------------------------------------------------------------
  auth_domain = var.application.auth_domain != "" ? var.application.auth_domain : null

  # -------------------------------------------------------------------------
  # Step 3: Identity-Aware Proxy for zero-trust application access control.
  # Only rendered when iap_enabled = true.
  # -------------------------------------------------------------------------
  dynamic "iap" {
    for_each = var.application.iap_enabled ? [1] : []
    content {
      enabled              = true
      oauth2_client_id     = var.application.iap_oauth2_client_id
      oauth2_client_secret = var.application.iap_oauth2_client_secret
    }
  }

  # -------------------------------------------------------------------------
  # Step 4: Feature settings — split health checks reduce deployment downtime
  # by checking readiness before routing traffic to new instances.
  # -------------------------------------------------------------------------
  feature_settings {
    split_health_checks = var.application.feature_settings_split_health_checks
  }
}

# ---------------------------------------------------------------------------
# Step 5: URL dispatch rules routing incoming requests to specific services
# by domain and path patterns. Created once per application when non-empty.
# ---------------------------------------------------------------------------
resource "google_app_engine_application_url_dispatch_rules" "dispatch" {
  count   = length(var.dispatch_rules) > 0 ? 1 : 0
  project = var.project_id

  # Each rule maps a (domain, path) pattern to a named service.
  dynamic "dispatch_rules" {
    for_each = var.dispatch_rules
    content {
      domain  = dispatch_rules.value.domain
      path    = dispatch_rules.value.path
      service = dispatch_rules.value.service
    }
  }

  depends_on = [google_app_engine_application.app]
}

# ---------------------------------------------------------------------------
# Step 6: Standard environment service versions.
# Standard runs in Google-managed sandboxes; supports scale-to-zero.
# Kept in a separate resource from flexible to avoid argument conflicts —
# liveness_check and readiness_check are flexible-only provider fields.
# ---------------------------------------------------------------------------
resource "google_app_engine_standard_app_version" "standard" {
  for_each = local.standard_services_map

  project    = each.value.project_id
  service    = each.value.service
  version_id = each.value.version_id
  runtime    = each.value.runtime

  # Lifecycle: noop_on_destroy = true prevents accidental version deletion.
  # Versions accumulate in App Engine and traffic splits are managed separately.
  noop_on_destroy           = each.value.noop_on_destroy
  delete_service_on_destroy = each.value.delete_service_on_destroy

  instance_class      = each.value.instance_class
  threadsafe          = each.value.threadsafe
  env_variables       = each.value.env_variables
  inbound_services    = length(each.value.inbound_services) > 0 ? each.value.inbound_services : null
  runtime_api_version = each.value.runtime_api_version != "" ? each.value.runtime_api_version : null

  # -------------------------------------------------------------------------
  # Step 7: Entrypoint shell command used to start the service process.
  # Required by the provider; uses entrypoint_shell if provided, else "exec gunicorn".
  # -------------------------------------------------------------------------
  entrypoint {
    shell = each.value.entrypoint_shell != "" ? each.value.entrypoint_shell : "exec gunicorn"
  }

  # -------------------------------------------------------------------------
  # Step 8: Deployment source — ZIP archive from a GCS object URL.
  # Only the block matching deployment_type is rendered; zip and files
  # are mutually exclusive. Container is prevented by variable validation.
  # -------------------------------------------------------------------------
  deployment {
    dynamic "zip" {
      for_each = each.value.deployment_type == "zip" ? [each.value] : []
      content {
        source_url  = zip.value.deployment_zip_source_url
        files_count = zip.value.deployment_zip_files_count > 0 ? zip.value.deployment_zip_files_count : null
      }
    }

    # -------------------------------------------------------------------------
    # Step 9: Deployment source — individual files uploaded to GCS.
    # Only rendered when deployment_type = "files".
    # -------------------------------------------------------------------------
    dynamic "files" {
      for_each = each.value.deployment_type == "files" ? each.value.deployment_files : []
      content {
        name       = files.value.name
        source_url = files.value.source_url
        sha1_sum   = files.value.sha1_sum != "" ? files.value.sha1_sum : null
      }
    }
  }

  # -------------------------------------------------------------------------
  # Step 10: Automatic scaling — adjusts instance count from load signals.
  # Conflicts with basic_scaling and manual_scaling; only one block fires.
  # -------------------------------------------------------------------------
  dynamic "automatic_scaling" {
    for_each = each.value.scaling_type == "automatic" ? [each.value] : []
    content {
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      max_idle_instances      = automatic_scaling.value.max_idle_instances
      max_pending_latency     = automatic_scaling.value.max_pending_latency
      min_idle_instances      = automatic_scaling.value.min_idle_instances
      min_pending_latency     = automatic_scaling.value.min_pending_latency

      standard_scheduler_settings {
        target_cpu_utilization        = automatic_scaling.value.target_cpu_utilization
        target_throughput_utilization = automatic_scaling.value.target_throughput_utilization
        min_instances                 = automatic_scaling.value.min_instances
        max_instances                 = automatic_scaling.value.max_instances
      }
    }
  }

  # -------------------------------------------------------------------------
  # Step 11: Basic scaling — creates instances on demand, idles when quiet.
  # More cost-effective for low-traffic services. Standard environment only.
  # -------------------------------------------------------------------------
  dynamic "basic_scaling" {
    for_each = each.value.scaling_type == "basic" ? [each.value] : []
    content {
      idle_timeout  = basic_scaling.value.basic_scaling_idle_timeout
      max_instances = basic_scaling.value.basic_scaling_max_instances
    }
  }

  # -------------------------------------------------------------------------
  # Step 12: Manual scaling — fixed instance count, never auto-scales.
  # -------------------------------------------------------------------------
  dynamic "manual_scaling" {
    for_each = each.value.scaling_type == "manual" ? [each.value] : []
    content {
      instances = manual_scaling.value.manual_scaling_instances
    }
  }

  depends_on = [google_app_engine_application.app]
}

# ---------------------------------------------------------------------------
# Step 13: Flexible environment service versions.
# Flexible runs Docker containers on Compute Engine VMs; any runtime via
# custom Dockerfile. liveness_check and readiness_check are provider-required.
# ---------------------------------------------------------------------------
resource "google_app_engine_flexible_app_version" "flexible" {
  for_each = local.flexible_services_map

  project    = each.value.project_id
  service    = each.value.service
  version_id = each.value.version_id
  runtime    = each.value.runtime

  noop_on_destroy           = each.value.noop_on_destroy
  delete_service_on_destroy = each.value.delete_service_on_destroy

  env_variables = each.value.env_variables

  # -------------------------------------------------------------------------
  # Step 14: Entrypoint shell command for the flexible container.
  # -------------------------------------------------------------------------
  dynamic "entrypoint" {
    for_each = each.value.entrypoint_shell != "" ? [each.value.entrypoint_shell] : []
    content {
      shell = entrypoint.value
    }
  }

  # -------------------------------------------------------------------------
  # Step 15: Deployment source — ZIP, pre-built container image, or files.
  # Only the block matching deployment_type is rendered to avoid conflicts.
  # -------------------------------------------------------------------------
  deployment {
    dynamic "zip" {
      for_each = each.value.deployment_type == "zip" ? [each.value] : []
      content {
        source_url  = zip.value.deployment_zip_source_url
        files_count = zip.value.deployment_zip_files_count > 0 ? zip.value.deployment_zip_files_count : null
      }
    }

    dynamic "container" {
      for_each = each.value.deployment_type == "container" ? [each.value.deployment_container_image] : []
      content {
        image = container.value
      }
    }

    dynamic "files" {
      for_each = each.value.deployment_type == "files" ? each.value.deployment_files : []
      content {
        name       = files.value.name
        source_url = files.value.source_url
        sha1_sum   = files.value.sha1_sum != "" ? files.value.sha1_sum : null
      }
    }
  }

  # -------------------------------------------------------------------------
  # Step 16: Compute resource allocation for each flexible instance.
  # -------------------------------------------------------------------------
  resources {
    cpu       = each.value.resources_cpu
    disk_gb   = each.value.resources_disk_gb
    memory_gb = each.value.resources_memory_gb
  }

  # -------------------------------------------------------------------------
  # Step 17: Liveness check — determines whether a running instance is
  # healthy. Failed checks trigger an instance restart. Provider-required.
  # -------------------------------------------------------------------------
  liveness_check {
    path              = each.value.liveness_check_path
    initial_delay     = each.value.liveness_check_initial_delay
    check_interval    = each.value.liveness_check_check_interval
    timeout           = each.value.liveness_check_timeout
    failure_threshold = each.value.liveness_check_failure_threshold
    success_threshold = each.value.liveness_check_success_threshold
  }

  # -------------------------------------------------------------------------
  # Step 18: Readiness check — gates traffic to a new instance until it
  # passes. Failed checks hold traffic on existing instances. Provider-required.
  # -------------------------------------------------------------------------
  readiness_check {
    path              = each.value.readiness_check_path
    check_interval    = each.value.readiness_check_check_interval
    timeout           = each.value.readiness_check_timeout
    failure_threshold = each.value.readiness_check_failure_threshold
    success_threshold = each.value.readiness_check_success_threshold
    app_start_timeout = each.value.readiness_check_app_start_timeout
  }

  # -------------------------------------------------------------------------
  # Step 19: Automatic scaling — scales flexible VMs based on CPU utilization.
  # Conflicts with manual_scaling; only one block fires per entry.
  # -------------------------------------------------------------------------
  dynamic "automatic_scaling" {
    for_each = each.value.scaling_type == "automatic" ? [each.value] : []
    content {
      min_total_instances = automatic_scaling.value.min_instances
      max_total_instances = automatic_scaling.value.max_instances
      cool_down_period    = automatic_scaling.value.flex_cool_down_period

      cpu_utilization {
        target_utilization        = automatic_scaling.value.target_cpu_utilization
        aggregation_window_length = automatic_scaling.value.flex_aggregation_window_length
      }
    }
  }

  # -------------------------------------------------------------------------
  # Step 20: Manual scaling — fixed instance count for flexible services.
  # -------------------------------------------------------------------------
  dynamic "manual_scaling" {
    for_each = each.value.scaling_type == "manual" ? [each.value] : []
    content {
      instances = manual_scaling.value.manual_scaling_instances
    }
  }

  depends_on = [google_app_engine_application.app]
}

# ---------------------------------------------------------------------------
# Step 21: Traffic split per service — enables canary deploys and blue/green
# rollouts by distributing traffic across multiple versions by weight.
# ---------------------------------------------------------------------------
resource "google_app_engine_service_split_traffic" "split" {
  for_each = local.split_traffic_map

  project = each.value.project_id
  service = each.value.service

  split {
    shard_by    = each.value.traffic_split_shard_by
    allocations = each.value.traffic_allocations
  }

  depends_on = [
    google_app_engine_standard_app_version.standard,
    google_app_engine_flexible_app_version.flexible,
  ]
}

# ---------------------------------------------------------------------------
# Step 22: Firewall rules restricting inbound traffic to the application.
# Rules are evaluated in ascending priority order; lowest number wins.
# ---------------------------------------------------------------------------
resource "google_app_engine_firewall_rule" "rule" {
  for_each = local.firewall_rules_map

  project      = var.project_id
  priority     = each.value.priority
  action       = each.value.action
  source_range = each.value.source_range
  description  = each.value.description != "" ? each.value.description : null

  depends_on = [google_app_engine_application.app]
}

# ---------------------------------------------------------------------------
# Step 23: Custom domain mappings for the App Engine application.
# After creation, retrieve dns_records output and add to your DNS provider.
# ---------------------------------------------------------------------------
resource "google_app_engine_domain_mapping" "mapping" {
  for_each = local.domain_mappings_map

  project           = var.project_id
  domain_name       = each.value.domain_name
  override_strategy = each.value.override_strategy

  # -------------------------------------------------------------------------
  # Step 24: TLS/SSL certificate settings for the custom domain.
  # Only rendered when ssl_management_type is set.
  # -------------------------------------------------------------------------
  dynamic "ssl_settings" {
    for_each = each.value.ssl_management_type != "" ? [each.value] : []
    content {
      certificate_id      = ssl_settings.value.ssl_certificate_id != "" ? ssl_settings.value.ssl_certificate_id : null
      ssl_management_type = ssl_settings.value.ssl_management_type
    }
  }

  depends_on = [google_app_engine_application.app]
}
