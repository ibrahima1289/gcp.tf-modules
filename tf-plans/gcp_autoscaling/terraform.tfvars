project_id = "main-project-492903"
region     = "us-central1"

tags = {
  owner       = "platform-team"
  environment = "production"
  team        = "infrastructure"
}

autoscalers = [

  # ── Web Tier — Regional, CPU + Predictive + Scale-In Control ──────────────
  # Scales a regional MIG across all zones in us-central1.
  # Predictive autoscaling pre-scales before expected demand.
  # Scale-in control limits removal to 2 VMs per 5-minute window.
  {
    key    = "web-regional"
    name   = "web-mig-autoscaler"
    region = "us-central1"
    target = "https://www.googleapis.com/compute/v1/projects/main-project-492903/regions/us-central1/instanceGroupManagers/web-mig"
    create = false # enable once web-mig MIG is provisioned

    min_replicas    = 2
    max_replicas    = 20
    cooldown_period = 60
    mode            = "ON"

    cpu_utilization = {
      target            = 0.60
      predictive_method = "OPTIMIZE_AVAILABILITY"
    }

    scale_in_control = {
      time_window_sec              = 300
      max_scaled_in_replicas_fixed = 2
    }
  },

  # ── API Tier — Regional, HTTP LB Utilization ──────────────────────────────
  # Scales based on the fraction of backend serving capacity used by the
  # HTTP(S) Load Balancer. Requires a backend service with the MIG.
  {
    key    = "api-lb"
    name   = "api-mig-autoscaler"
    region = "us-central1"
    target = "https://www.googleapis.com/compute/v1/projects/main-project-492903/regions/us-central1/instanceGroupManagers/api-mig"
    create = false # enable once api-mig MIG is provisioned

    min_replicas = 3
    max_replicas = 50

    load_balancing_utilization = {
      target = 0.80
    }

    scale_in_control = {
      time_window_sec                = 600
      max_scaled_in_replicas_percent = 10 # remove at most 10% of current fleet per window
    }
  },

  # ── Worker Tier — Regional, Pub/Sub Queue Depth ───────────────────────────
  # Scales based on undelivered Pub/Sub messages.
  # single_instance_assignment = 50 means 1 VM is provisioned per 50 messages.
  {
    key    = "worker-pubsub"
    name   = "worker-mig-autoscaler"
    region = "us-central1"
    target = "https://www.googleapis.com/compute/v1/projects/main-project-492903/regions/us-central1/instanceGroupManagers/worker-mig"
    create = false # enable once worker-mig MIG is provisioned

    min_replicas    = 1
    max_replicas    = 30
    cooldown_period = 90

    metrics = [
      {
        name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
        filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = worker-task-sub"
        single_instance_assignment = 50  # type must not be set alongside single_instance_assignment
      }
    ]
  },

  # ── Batch Tier — Regional, Scheduling + CPU ───────────────────────────────
  # Combines CPU scaling with a scaling schedule that pre-provisions extra
  # capacity during business hours and end-of-month batch runs.
  {
    key    = "batch-scheduled"
    name   = "batch-mig-autoscaler"
    region = "us-central1"
    target = "https://www.googleapis.com/compute/v1/projects/main-project-492903/regions/us-central1/instanceGroupManagers/batch-mig"
    create = false # enable once batch-mig MIG is provisioned

    min_replicas = 1
    max_replicas = 40

    cpu_utilization = { target = 0.70 }

    scaling_schedules = [
      {
        name                  = "business-hours"
        min_required_replicas = 8
        schedule              = "0 8 * * MON-FRI"
        time_zone             = "America/Chicago"
        duration_sec          = 36000 # 10 hours
        description           = "Maintain minimum capacity during business hours"
      },
      {
        name                  = "end-of-month-batch"
        min_required_replicas = 20
        schedule              = "0 4 28-31 * *"
        time_zone             = "UTC"
        duration_sec          = 86400
        description           = "Extra capacity for end-of-month billing batch"
      }
    ]

    scale_in_control = {
      time_window_sec              = 600
      max_scaled_in_replicas_fixed = 3
    }
  },

  # ── GPU Tier — Zonal, CPU (disabled, enable once GPU MIG is created) ──────
  # Zonal autoscaler targeting GPU instances in a specific zone.
  # Set create = true once the zonal MIG is provisioned.
  {
    key    = "gpu-zonal"
    name   = "gpu-mig-autoscaler"
    zone   = "us-central1-a"
    target = "https://www.googleapis.com/compute/v1/projects/main-project-492903/zones/us-central1-a/instanceGroupManagers/gpu-mig"
    create = false # enable once GPU MIG is ready

    min_replicas = 0
    max_replicas = 8

    cpu_utilization = { target = 0.70 }
  },
]
