# ---------------------------------------------------------------------------
# Step 1: Regional MIG Autoscalers
# google_compute_region_autoscaler manages a regional Managed Instance Group
# (MIG) and scales it across multiple zones within a region. Regional MIGs
# provide higher availability than zonal MIGs and are the recommended choice
# for production workloads.
# ---------------------------------------------------------------------------
resource "google_compute_region_autoscaler" "regional" {
  for_each = local.regional_autoscalers_map

  project = each.value.project_id
  name    = each.value.name
  region  = each.value.region
  target  = each.value.target # self-link of the regional MIG to autoscale

  autoscaling_policy {
    min_replicas    = each.value.min_replicas
    max_replicas    = each.value.max_replicas
    cooldown_period = each.value.cooldown_period # seconds to wait after a scaling event
    mode            = each.value.mode            # ON | ONLY_UP | ONLY_SCALE_OUT | OFF

    # ── CPU Utilization Signal ─────────────────────────────────────────────
    # Scale based on average CPU utilization across the MIG. Optional
    # predictive autoscaling can pre-scale before demand arrives.
    dynamic "cpu_utilization" {
      for_each = each.value.cpu_utilization != null ? [each.value.cpu_utilization] : []
      content {
        target            = cpu_utilization.value.target
        predictive_method = cpu_utilization.value.predictive_method # NONE | OPTIMIZE_AVAILABILITY
      }
    }

    # ── HTTP Load Balancing Utilization Signal ──────────────────────────────
    # Scale based on the fraction of backend serving capacity used by the
    # Cloud HTTP(S) Load Balancer. Requires a backend service with the MIG.
    dynamic "load_balancing_utilization" {
      for_each = each.value.load_balancing_utilization != null ? [each.value.load_balancing_utilization] : []
      content {
        target = load_balancing_utilization.value.target # 0.0 – 1.0
      }
    }

    # ── Custom / Pub-Sub / Cloud Monitoring Metric Signals ─────────────────
    # One block per metric. Supports GAUGE, DELTA_PER_SECOND,
    # DELTA_PER_MINUTE types and per-instance or single_instance_assignment
    # scaling modes.
    dynamic "metric" {
      for_each = each.value.metrics
      content {
        name                       = metric.value.name
        filter                     = trimspace(metric.value.filter) != "" ? metric.value.filter : null
        target                     = metric.value.target != 0 ? metric.value.target : null
        type                       = metric.value.type
        single_instance_assignment = metric.value.single_instance_assignment != 0 ? metric.value.single_instance_assignment : null
      }
    }

    # ── Scaling Schedules ──────────────────────────────────────────────────
    # Override min_replicas during predictable high-demand windows (e.g. sales
    # events, batch jobs) using cron expressions in the specified time zone.
    dynamic "scaling_schedules" {
      for_each = each.value.scaling_schedules
      content {
        name                  = scaling_schedules.value.name
        min_required_replicas = scaling_schedules.value.min_required_replicas
        schedule              = scaling_schedules.value.schedule   # cron expression
        time_zone             = scaling_schedules.value.time_zone
        duration_sec          = scaling_schedules.value.duration_sec
        disabled              = scaling_schedules.value.disabled
        description           = trimspace(scaling_schedules.value.description) != "" ? scaling_schedules.value.description : null
      }
    }

    # ── Scale-In Control ───────────────────────────────────────────────────
    # Limits how aggressively the autoscaler removes VMs to prevent thrashing
    # during transient traffic dips. Defines the max VMs removed and the
    # time window over which that limit is applied.
    dynamic "scale_in_control" {
      for_each = each.value.scale_in_control != null ? [each.value.scale_in_control] : []
      content {
        time_window_sec = scale_in_control.value.time_window_sec

        max_scaled_in_replicas {
          fixed   = scale_in_control.value.max_scaled_in_replicas_fixed != 0 ? scale_in_control.value.max_scaled_in_replicas_fixed : null
          percent = scale_in_control.value.max_scaled_in_replicas_percent != 0 ? scale_in_control.value.max_scaled_in_replicas_percent : null
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Step 2: Zonal MIG Autoscalers
# google_compute_autoscaler manages a single-zone MIG. Use zonal autoscalers
# when you need to target a specific zone (e.g. GPU workloads, specific
# hardware) or when managing a pre-existing zonal MIG. For most production
# workloads prefer regional autoscalers (Step 1).
# ---------------------------------------------------------------------------
resource "google_compute_autoscaler" "zonal" {
  for_each = local.zonal_autoscalers_map

  project = each.value.project_id
  name    = each.value.name
  zone    = each.value.zone   # e.g. "us-central1-a"
  target  = each.value.target # self-link of the zonal MIG to autoscale

  autoscaling_policy {
    min_replicas    = each.value.min_replicas
    max_replicas    = each.value.max_replicas
    cooldown_period = each.value.cooldown_period
    mode            = each.value.mode

    dynamic "cpu_utilization" {
      for_each = each.value.cpu_utilization != null ? [each.value.cpu_utilization] : []
      content {
        target            = cpu_utilization.value.target
        predictive_method = cpu_utilization.value.predictive_method
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = each.value.load_balancing_utilization != null ? [each.value.load_balancing_utilization] : []
      content {
        target = load_balancing_utilization.value.target
      }
    }

    dynamic "metric" {
      for_each = each.value.metrics
      content {
        name                       = metric.value.name
        filter                     = trimspace(metric.value.filter) != "" ? metric.value.filter : null
        target                     = metric.value.target != 0 ? metric.value.target : null
        type                       = metric.value.single_instance_assignment == 0 ? metric.value.type : null
        single_instance_assignment = metric.value.single_instance_assignment != 0 ? metric.value.single_instance_assignment : null
      }
    }

    dynamic "scaling_schedules" {
      for_each = each.value.scaling_schedules
      content {
        name                  = scaling_schedules.value.name
        min_required_replicas = scaling_schedules.value.min_required_replicas
        schedule              = scaling_schedules.value.schedule
        time_zone             = scaling_schedules.value.time_zone
        duration_sec          = scaling_schedules.value.duration_sec
        disabled              = scaling_schedules.value.disabled
        description           = trimspace(scaling_schedules.value.description) != "" ? scaling_schedules.value.description : null
      }
    }

    dynamic "scale_in_control" {
      for_each = each.value.scale_in_control != null ? [each.value.scale_in_control] : []
      content {
        time_window_sec = scale_in_control.value.time_window_sec

        max_scaled_in_replicas {
          fixed   = scale_in_control.value.max_scaled_in_replicas_fixed != 0 ? scale_in_control.value.max_scaled_in_replicas_fixed : null
          percent = scale_in_control.value.max_scaled_in_replicas_percent != 0 ? scale_in_control.value.max_scaled_in_replicas_percent : null
        }
      }
    }
  }
}
