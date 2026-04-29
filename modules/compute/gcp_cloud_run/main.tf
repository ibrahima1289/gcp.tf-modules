# ===========================================================================
# Step 1: Cloud Run v2 Services
# Each entry in var.services creates one google_cloud_run_v2_service.
# Services handle HTTP requests and scale to zero automatically.
# ===========================================================================
resource "google_cloud_run_v2_service" "services" {
  for_each = { for s in var.services : s.key => s if s.create }

  project  = var.project_id
  name     = each.value.name
  location = trimspace(each.value.location) != "" ? each.value.location : var.region

  # Ingress controls which traffic sources can reach the service.
  # ALL = public internet; INTERNAL = VPC/internal LB only;
  # INTERNAL_AND_CLOUD_LOAD_BALANCING = internal + Cloud LB frontend.
  ingress = each.value.ingress

  # Labels applied to the Cloud Run service resource.
  labels = local.common_labels

  template {
    # Each unique revision_suffix creates a named revision; leave empty for
    # auto-generated revision names.
    revision = trimspace(each.value.revision_suffix) != "" ? "${each.value.name}-${each.value.revision_suffix}" : null

    # Service account the container identity runs as (Workload Identity).
    service_account = trimspace(each.value.service_account_email) != "" ? each.value.service_account_email : null

    # Concurrency and scaling controls.
    max_instance_request_concurrency = each.value.concurrency
    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }

    # Per-instance execution timeout (ISO 8601 duration, e.g. "300s").
    timeout = each.value.timeout

    # CPU is allocated "always" (background threads, lower latency) or only
    # during request handling (default, lowest cost).
    execution_environment = each.value.execution_environment

    # Direct VPC egress — route outbound traffic into a VPC without a connector.
    dynamic "vpc_access" {
      for_each = trimspace(each.value.vpc_network) != "" ? [1] : []
      content {
        # Use direct VPC egress when a connector name is not provided.
        dynamic "network_interfaces" {
          for_each = trimspace(each.value.vpc_connector) == "" ? [1] : []
          content {
            network    = each.value.vpc_network
            subnetwork = trimspace(each.value.vpc_subnetwork) != "" ? each.value.vpc_subnetwork : null
          }
        }
        connector = trimspace(each.value.vpc_connector) != "" ? each.value.vpc_connector : null
        egress    = each.value.vpc_egress
      }
    }

    # Labels applied to the revision template (propagated to each revision).
    labels = local.common_labels

    containers {
      # Container image from Artifact Registry or Container Registry.
      image = each.value.image

      # Override the container entrypoint command and arguments.
      command = length(each.value.command) > 0 ? each.value.command : null
      args    = length(each.value.args) > 0 ? each.value.args : null

      # HTTP port the container listens on (default 8080).
      ports {
        name           = "http1"
        container_port = each.value.port
      }

      # CPU and memory resource limits for each container instance.
      resources {
        limits = {
          cpu    = each.value.cpu
          memory = each.value.memory
        }
        # "cpu_idle = false" means CPU is always allocated even between requests.
        cpu_idle          = !each.value.cpu_always_allocated
        startup_cpu_boost = each.value.startup_cpu_boost
      }

      # Plain environment variables (non-sensitive key/value pairs).
      dynamic "env" {
        for_each = each.value.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret-backed environment variables from Secret Manager.
      dynamic "env" {
        for_each = each.value.secret_env_vars
        content {
          name = env.value.env_name
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }

      # Volume mounts — project-level Secret Manager secrets mounted as files.
      dynamic "volume_mounts" {
        for_each = each.value.secret_volumes
        content {
          name       = volume_mounts.value.volume_name
          mount_path = volume_mounts.value.mount_path
        }
      }
    }

    # Secret volumes declared at the template level (referenced by volume_mounts).
    dynamic "volumes" {
      for_each = each.value.secret_volumes
      content {
        name = volumes.value.volume_name
        secret {
          secret = volumes.value.secret
          dynamic "items" {
            for_each = volumes.value.items
            content {
              version = items.value.version
              path    = items.value.path
            }
          }
        }
      }
    }
  }

  # Traffic splitting — route percentages to specific revision tags or "LATEST".
  dynamic "traffic" {
    for_each = each.value.traffic
    content {
      type     = traffic.value.type
      revision = trimspace(traffic.value.revision) != "" ? traffic.value.revision : null
      tag      = trimspace(traffic.value.tag) != "" ? traffic.value.tag : null
      percent  = traffic.value.percent
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore client-only annotation injected by gcloud CLI on manual deployments.
      template[0].annotations,
    ]
  }
}

# ===========================================================================
# Step 2: Cloud Run v2 Jobs
# Each entry in var.jobs creates one google_cloud_run_v2_job.
# Jobs run to completion — ETL, batch processing, data migration tasks.
# ===========================================================================
resource "google_cloud_run_v2_job" "jobs" {
  for_each = { for j in var.jobs : j.key => j if j.create }

  project  = var.project_id
  name     = each.value.name
  location = trimspace(each.value.location) != "" ? each.value.location : var.region

  labels = local.common_labels

  template {
    # Number of times a failed task is retried before the job fails.
    task_count  = each.value.task_count
    parallelism = each.value.parallelism

    template {
      # Per-task wall-clock timeout (ISO 8601 duration, e.g. "3600s").
      timeout         = each.value.timeout
      max_retries     = each.value.max_retries
      service_account = trimspace(each.value.service_account_email) != "" ? each.value.service_account_email : null

      containers {
        image   = each.value.image
        command = length(each.value.command) > 0 ? each.value.command : null
        args    = length(each.value.args) > 0 ? each.value.args : null

        resources {
          limits = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }

        # Plain environment variables.
        dynamic "env" {
          for_each = each.value.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        # Secret-backed environment variables from Secret Manager.
        dynamic "env" {
          for_each = each.value.secret_env_vars
          content {
            name = env.value.env_name
            value_source {
              secret_key_ref {
                secret  = env.value.secret
                version = env.value.version
              }
            }
          }
        }
      }

      # Direct VPC egress for jobs that need access to private resources.
      dynamic "vpc_access" {
        for_each = trimspace(each.value.vpc_network) != "" ? [1] : []
        content {
          dynamic "network_interfaces" {
            for_each = trimspace(each.value.vpc_connector) == "" ? [1] : []
            content {
              network    = each.value.vpc_network
              subnetwork = trimspace(each.value.vpc_subnetwork) != "" ? each.value.vpc_subnetwork : null
            }
          }
          connector = trimspace(each.value.vpc_connector) != "" ? each.value.vpc_connector : null
          egress    = each.value.vpc_egress
        }
      }
    }
  }
}

# ===========================================================================
# Step 3: IAM — Allow unauthenticated invocations (public services)
# Only created when allow_unauthenticated = true on a service entry.
# For authenticated services, control access by granting roles/run.invoker
# to specific identities outside this module.
# ===========================================================================
resource "google_cloud_run_v2_service_iam_member" "public" {
  for_each = {
    for s in var.services : s.key => s
    if s.create && s.allow_unauthenticated
  }

  project  = var.project_id
  location = trimspace(each.value.location) != "" ? each.value.location : var.region
  name     = google_cloud_run_v2_service.services[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ===========================================================================
# Step 4: IAM — Specific invoker bindings for authenticated services
# Grant roles/run.invoker to explicit identities per service entry.
# ===========================================================================
resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = {
    for pair in flatten([
      for s in var.services : [
        for m in s.invoker_members : {
          key      = "${s.key}/${m}"
          svc_key  = s.key
          location = trimspace(s.location) != "" ? s.location : var.region
          name     = s.name
          member   = m
        }
      ]
      if s.create
    ]) : pair.key => pair
  }

  project  = var.project_id
  location = each.value.location
  name     = google_cloud_run_v2_service.services[each.value.svc_key].name
  role     = "roles/run.invoker"
  member   = each.value.member
}
