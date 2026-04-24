# GCP Autoscaling Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for deploying [Google Cloud Autoscalers](https://cloud.google.com/compute/docs/autoscaler) against regional and zonal Managed Instance Groups (MIGs). Supports CPU utilization, HTTP Load Balancing utilization, custom Cloud Monitoring metrics, Pub/Sub queue depth, scaling schedules, and scale-in controls to prevent thrashing.

---

## Architecture

```text
GCP Project
└── Region / Zone
    │
    ├── Managed Instance Group (MIG)  ← pre-existing, referenced by self-link
    │   ├── Instance 1
    │   ├── Instance 2
    │   └── Instance N  (scaled between min_replicas and max_replicas)
    │
    └── Autoscaler  (google_compute_region_autoscaler or google_compute_autoscaler)
        │
        ├── Signal: CPU Utilization  ─── target 0.60 → scale at 60% avg CPU
        │   └── Predictive: OPTIMIZE_AVAILABILITY  ← pre-scale before demand
        │
        ├── Signal: HTTP LB Utilization  ─── fraction of backend capacity
        │
        ├── Signal: Custom Metric  ─── Cloud Monitoring or Pub/Sub queue depth
        │   └── single_instance_assignment: 50 msgs/VM
        │
        ├── Signal: Scaling Schedule  ─── cron override for known traffic peaks
        │   └── "0 8 * * MON-FRI" → min 10 VMs during business hours
        │
        └── Scale-In Control  ─── max 2 VMs removed per 5-minute window
```

---

## Resources Created

| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| Regional Autoscaler | `google_compute_region_autoscaler` | Autoscales a regional MIG across zones |
| Zonal Autoscaler | `google_compute_autoscaler` | Autoscales a single-zone MIG |

> **Managed Instance Groups are not created by this module.** Create the MIG separately and pass its self-link to the `target` field. For regional MIGs use `google_compute_region_instance_group_manager`; for zonal MIGs use `google_compute_instance_group_manager`.

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5 |
| hashicorp/google | >= 6.0 |

---

## Usage

### Regional autoscaler — CPU + Predictive scaling

```hcl
module "autoscaling" {
  source     = "../../modules/networking/gcp_autoscaling"
  project_id = "my-project-id"
  region     = "us-central1"
  tags       = { environment = "production", team = "platform" }

  autoscalers = [
    {
      key    = "web-regional"
      name   = "web-mig-autoscaler"
      region = "us-central1"
      target = "https://www.googleapis.com/compute/v1/projects/my-project-id/regions/us-central1/instanceGroupManagers/web-mig"

      min_replicas    = 2
      max_replicas    = 20
      cooldown_period = 60

      cpu_utilization = {
        target            = 0.60
        predictive_method = "OPTIMIZE_AVAILABILITY"
      }

      scale_in_control = {
        time_window_sec              = 300
        max_scaled_in_replicas_fixed = 2
      }
    }
  ]
}
```

### HTTP Load Balancing utilization signal

```hcl
autoscalers = [
  {
    key    = "api-lb-scaling"
    name   = "api-mig-autoscaler"
    region = "us-central1"
    target = google_compute_region_instance_group_manager.api.id

    min_replicas = 3
    max_replicas = 50

    load_balancing_utilization = {
      target = 0.80  # scale when 80% of LB backend capacity is used
    }
  }
]
```

### Pub/Sub queue depth signal (single_instance_assignment)

```hcl
autoscalers = [
  {
    key    = "worker-pubsub"
    name   = "worker-mig-autoscaler"
    region = "us-central1"
    target = google_compute_region_instance_group_manager.worker.id

    min_replicas = 1
    max_replicas = 30

    metrics = [
      {
        name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
        filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = my-worker-sub"
        type                       = "GAUGE"
        single_instance_assignment = 50  # 1 VM per 50 messages
      }
    ]
  }
]
```

### Scaling schedule — pre-scale for known traffic windows

```hcl
autoscalers = [
  {
    key    = "web-scheduled"
    name   = "web-scheduled-autoscaler"
    region = "us-central1"
    target = google_compute_region_instance_group_manager.web.id

    min_replicas = 2
    max_replicas = 40
    mode         = "ON"

    scaling_schedules = [
      {
        name                  = "business-hours"
        min_required_replicas = 10
        schedule              = "0 8 * * MON-FRI"
        time_zone             = "America/Chicago"
        duration_sec          = 36000  # 10 hours
      },
      {
        name                  = "end-of-month-batch"
        min_required_replicas = 25
        schedule              = "0 6 28-31 * *"
        time_zone             = "UTC"
        duration_sec          = 86400
        description           = "Extra capacity for end-of-month billing batch"
      }
    ]
  }
]
```

### Zonal autoscaler

```hcl
autoscalers = [
  {
    key    = "gpu-zonal"
    name   = "gpu-mig-autoscaler"
    zone   = "us-central1-a"
    target = google_compute_instance_group_manager.gpu.id

    min_replicas = 0
    max_replicas = 8

    cpu_utilization = { target = 0.70 }
  }
]
```

---

## Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project_id` | `string` | ✅ | — | Default GCP project ID |
| `region` | `string` | | `us-central1` | Default region for regional autoscalers |
| `tags` | `map(string)` | | `{}` | Common governance labels |
| `autoscalers` | `list(object)` | | `[]` | Autoscaler configurations (see below) |

### `autoscalers[*]` object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `key` | `string` | ✅ | — | Unique key for this autoscaler |
| `create` | `bool` | | `true` | Set `false` to skip creation |
| `name` | `string` | ✅ | — | Autoscaler resource name |
| `project_id` | `string` | | `""` | Per-item project override |
| `region` | `string` | ✅ or `zone` | `""` | Region for regional autoscaler |
| `zone` | `string` | ✅ or `region` | `""` | Zone for zonal autoscaler |
| `target` | `string` | ✅ | — | MIG self-link or id |
| `min_replicas` | `number` | ✅ | — | Minimum number of VMs |
| `max_replicas` | `number` | ✅ | — | Maximum number of VMs |
| `cooldown_period` | `number` | | `60` | Seconds to wait after scaling |
| `mode` | `string` | | `ON` | `ON` / `ONLY_UP` / `ONLY_SCALE_OUT` / `OFF` |
| `cpu_utilization` | `object` | | `null` | CPU utilization signal |
| `load_balancing_utilization` | `object` | | `null` | HTTP LB utilization signal |
| `metrics` | `list(object)` | | `[]` | Custom metric signals |
| `scaling_schedules` | `list(object)` | | `[]` | Cron-based min replica overrides |
| `scale_in_control` | `object` | | `null` | Limit scale-in rate |

---

## Outputs

| Name | Description |
|------|-------------|
| `autoscaler_ids` | All autoscaler IDs keyed by `key` |
| `autoscaler_names` | All autoscaler names keyed by `key` |
| `autoscaler_self_links` | All autoscaler self-links keyed by `key` |
| `regional_autoscaler_ids` | Regional autoscaler IDs only |
| `zonal_autoscaler_ids` | Zonal autoscaler IDs only |
| `common_labels` | Governance labels generated by this module |

---

## Notes

- **Regional vs Zonal**: Set `region` for a regional autoscaler (`google_compute_region_autoscaler`). Set `zone` for a zonal autoscaler (`google_compute_autoscaler`). You cannot set both.
- **Multiple signals**: When multiple signals are present, the autoscaler scales to the highest recommendation from any signal.
- **Predictive autoscaling**: Only available with `cpu_utilization`; set `predictive_method = "OPTIMIZE_AVAILABILITY"` to pre-scale before predicted demand.
- **Scale-in control**: Use `max_scaled_in_replicas_fixed` (absolute count) OR `max_scaled_in_replicas_percent` (percentage of current size), not both.
- **Cooldown period**: Must be at least as long as your application startup time to avoid premature scale-in.
