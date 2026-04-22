# GCP Autoscaling

[Compute Engine Autoscaling](https://cloud.google.com/compute/docs/autoscaler) automatically adjusts the number of VM instances in a **Managed Instance Group (MIG)** based on load signals — CPU utilization, HTTP load balancing capacity, Cloud Monitoring metrics, or schedule. Combined with **GKE Node Auto-provisioning** and **Cloud Run automatic scaling**, autoscaling is the primary cost and reliability lever for compute workloads on GCP.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **MIG Autoscaler** | Scales VM count in a regional or zonal MIG based on configurable signals |
| **Scale-out / scale-in** | Adds instances when load rises; removes instances (with configurable cooldown) when load drops |
| **Multiple signals** | CPU, HTTP LB utilization, Pub/Sub queue depth, custom Cloud Monitoring metrics — combinable |
| **Predictive autoscaling** | Forecasts load from historical patterns to scale proactively before demand arrives |
| **Scale-in controls** | Minimum wait time and max-scale-in-replicas guards to prevent thrashing |
| **GKE Node Auto-provisioning** | Automatically creates and removes node pools based on pod scheduling demand |
| **Cloud Run** | Scales container instances from 0 to max concurrently; no autoscaler resource needed |

---

## Core Concepts

### Managed Instance Groups (MIGs)

An autoscaler always targets a MIG. The MIG defines the instance template (machine type, disk, startup script) and the autoscaler controls the replica count within `min_replicas` and `max_replicas`.

```text
Load Balancer  ──►  Backend Service  ──►  MIG  ──►  VM instances
                                           ▲
                                      Autoscaler
                                     (signals → replica target)
```

### Autoscaling Signals

| Signal | Resource Field | Use Case |
|--------|---------------|---------|
| CPU utilization | `cpu_utilization.target` | General-purpose compute scaling |
| HTTP LB serving capacity | `load_balancing_utilization.target` | Web tier — scale on backend utilization |
| Pub/Sub subscription backlog | `metric` with `pubsub.googleapis.com/subscription/num_undelivered_messages` | Queue worker scaling |
| Custom Cloud Monitoring metric | `metric.name` (any GAUGE metric) | App-specific SLO-driven scaling |
| Schedule | `scaling_schedules` | Pre-scale for predictable traffic bursts |

Multiple signals can be combined; the autoscaler uses the signal that requires the **most instances**.

### Scale-In Controls

Aggressive scale-in causes instance churn and potential request drops. Use scale-in controls to limit how fast instances are removed:

```hcl
scale_in_control {
  max_scaled_in_replicas {
    fixed   = 3      # or: percent = 10 (max 10% of current count removed per window)
  }
  time_window_sec = 300  # scale-in decisions evaluated over this rolling window
}
```

### Predictive Autoscaling

```hcl
autoscaling_policy {
  mode = "ON"  # ON | OFF | ONLY_UP | ONLY_SCALE_OUT

  cpu_utilization {
    target             = 0.6
    predictive_method  = "OPTIMIZE_AVAILABILITY"  # NONE | OPTIMIZE_AVAILABILITY
  }
}
```

`OPTIMIZE_AVAILABILITY` uses ML-based load forecasting to add capacity before the predicted peak — effective for recurring daily/weekly traffic patterns.

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_compute_autoscaler` | Zonal autoscaler attached to a zonal MIG |
| `google_compute_region_autoscaler` | Regional autoscaler attached to a regional MIG |
| `google_compute_instance_group_manager` | Zonal MIG (autoscaler target) |
| `google_compute_region_instance_group_manager` | Regional MIG (autoscaler target) — preferred for HA |

---

## HCL Examples

### Regional MIG + CPU Autoscaler

```hcl
# Instance template — defines machine type, image, and startup config
resource "google_compute_instance_template" "web" {
  name_prefix  = "web-"
  machine_type = "e2-medium"

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = "default"
    access_config {}
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Regional MIG — distributes instances across zones for HA
resource "google_compute_region_instance_group_manager" "web" {
  name               = "web-mig"
  base_instance_name = "web"
  region             = "us-central1"

  version {
    instance_template = google_compute_instance_template.web.id
  }

  # Initial size; autoscaler controls this after creation
  target_size = 2

  named_port {
    name = "http"
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 120
  }
}

# Regional autoscaler — scale on CPU utilization
resource "google_compute_region_autoscaler" "web" {
  name   = "web-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = 2    # never drop below this count
    max_replicas    = 20   # never exceed this count
    cooldown_period = 60   # seconds to wait after a scale event before re-evaluating

    cpu_utilization {
      target            = 0.6  # target 60% average CPU across the MIG
      predictive_method = "OPTIMIZE_AVAILABILITY"
    }

    # Prevent aggressive scale-in: at most 2 instances removed per 5-minute window
    scale_in_control {
      max_scaled_in_replicas {
        fixed = 2
      }
      time_window_sec = 300
    }
  }
}
```

### HTTP Load Balancing Utilization Signal

```hcl
resource "google_compute_region_autoscaler" "web_lb" {
  name   = "web-lb-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 30
    cooldown_period = 90

    # Scale based on backend service utilization reported by the HTTP LB
    load_balancing_utilization {
      target = 0.8  # scale out when LB capacity utilization exceeds 80%
    }
  }
}
```

### Pub/Sub Queue Worker Scaling

```hcl
resource "google_compute_region_autoscaler" "worker" {
  name   = "pubsub-worker-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.worker.id

  autoscaling_policy {
    min_replicas    = 1
    max_replicas    = 50
    cooldown_period = 30

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = \"my-job-sub\""
      single_instance_assignment = 200  # target 200 unacked messages per worker instance
    }
  }
}
```

### Schedule-Based Pre-scaling

```hcl
resource "google_compute_region_autoscaler" "batch" {
  name   = "batch-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.batch.id

  autoscaling_policy {
    min_replicas    = 1
    max_replicas    = 100
    cooldown_period = 60
    mode            = "ON"

    cpu_utilization {
      target = 0.7
    }

    # Pre-scale to 20 instances every weekday morning before the batch job starts
    scaling_schedules {
      name                  = "weekday-morning"
      min_required_replicas = 20
      schedule              = "0 8 * * 1-5"  # cron: 08:00 Mon–Fri
      time_zone             = "America/Chicago"
      duration_sec          = 3600  # hold for 1 hour, then return to metric-based scaling
    }
  }
}
```

### Custom Cloud Monitoring Metric

```hcl
resource "google_compute_region_autoscaler" "app" {
  name   = "app-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.app.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 40
    cooldown_period = 60

    metric {
      name   = "custom.googleapis.com/app/queue_depth"
      type   = "GAUGE"
      target = 100.0  # scale out when queue_depth per instance exceeds 100
    }
  }
}
```

---

## Autoscaling Modes

| Mode | Behaviour |
|------|-----------|
| `ON` | Scale both up and down (default) |
| `ONLY_UP` | Scale out only — useful during canary rollouts |
| `ONLY_SCALE_OUT` | Alias for `ONLY_UP` |
| `OFF` | Autoscaler paused; MIG retains current size |

---

## GKE Cluster Autoscaler

GKE manages its own autoscaler at the node pool level. Terraform enables it via the `autoscaling` block on `google_container_node_pool`:

```hcl
resource "google_container_node_pool" "default" {
  name    = "default"
  cluster = google_container_cluster.main.name

  autoscaling {
    min_node_count = 1
    max_node_count = 20
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
```

**Node Auto-provisioning** (cluster-level) automatically creates new node pools when pods cannot be scheduled; configure it via `cluster_autoscaling` in `google_container_cluster`:

```hcl
resource "google_container_cluster" "main" {
  name = "main-cluster"

  cluster_autoscaling {
    enabled = true

    resource_limits {
      resource_type = "cpu"
      minimum       = 4
      maximum       = 256
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 16
      maximum       = 1024
    }

    auto_provisioning_defaults {
      machine_type = "e2-standard-4"
      disk_size    = 100
      disk_type    = "pd-standard"
    }
  }
}
```

---

## Cloud Run Scaling

Cloud Run scales container instances automatically without a separate autoscaler resource:

```hcl
resource "google_cloud_run_v2_service" "api" {
  name     = "api"
  location = "us-central1"

  template {
    scaling {
      min_instance_count = 1   # keep at least 1 warm to avoid cold starts
      max_instance_count = 50  # hard cap on concurrent instances
    }

    containers {
      image = "gcr.io/my-project/api:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }
}
```

---

## Best Practices

| Practice | Guidance |
|----------|---------|
| **Set realistic `min_replicas`** | Never set to 0 for user-facing services — cold start latency hurts SLOs |
| **Use `cooldown_period`** | Allow 60–120 s for instances to warm up before re-evaluating signals |
| **Apply scale-in controls** | Prevent thrashing by limiting removal rate with `scale_in_control` |
| **Target 60–70% CPU** | Leave headroom for traffic spikes before scale-out kicks in |
| **Use predictive autoscaling** | Enable `OPTIMIZE_AVAILABILITY` for services with recurring daily patterns |
| **Combine signals carefully** | Autoscaler always picks the signal requiring *most* instances — don't combine conflicting targets |
| **Use schedules for known bursts** | Pre-scale before batch jobs or marketing events to avoid under-provisioning lag |
| **Monitor autoscaler decisions** | Alert on `compute.googleapis.com/autoscaler/capacity_metrics` and scaling decisions in Cloud Monitoring |
| **Set instance health checks** | Always configure `auto_healing_policies` on MIGs to replace unhealthy instances |

---

## Cost Considerations

- Autoscaling VMs are billed at the standard Compute Engine per-second rate; no extra charge for the autoscaler itself.
- Sustained Use Discounts (SUD) and Committed Use Discounts (CUD) apply to baseline steady-state usage — autoscaled burst capacity is billed at on-demand rates.
- Set a conservative `max_replicas` to cap runaway scaling costs.
- Use **Spot VMs** (`scheduling.preemptible = true` or `provisioning_model = "SPOT"`) for fault-tolerant workloads to reduce burst costs by up to 90%.

---

## Security Guidance

- Assign a **dedicated service account** to the instance template with least-privilege roles; avoid the default Compute SA (`-compute@developer.gserviceaccount.com`).
- Use **OS Login** (`enable-oslogin = "true"` metadata) instead of project-wide SSH keys on autoscaled MIGs.
- Disable public IPs on MIG instances and route traffic through an Internal Load Balancer or Cloud NAT.
- Tag MIG instances with a **network tag** and apply firewall rules to that tag — rules automatically apply to all scaled instances.
- Use **Confidential VMs** for sensitive workloads: set `confidential_instance_config { enable_confidential_compute = true }` in the instance template.

---

## Related Docs

- [Compute Engine Autoscaler overview](https://cloud.google.com/compute/docs/autoscaler)
- [Autoscaling policies](https://cloud.google.com/compute/docs/autoscaler/scaling-policies)
- [Predictive autoscaling](https://cloud.google.com/compute/docs/autoscaler/predictive-autoscaling)
- [GKE Cluster Autoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler)
- [GKE Node Auto-provisioning](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning)
- [Cloud Run scaling](https://cloud.google.com/run/docs/about-instance-autoscaling)
- [google_compute_region_autoscaler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_autoscaler)
- [google_compute_region_instance_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
