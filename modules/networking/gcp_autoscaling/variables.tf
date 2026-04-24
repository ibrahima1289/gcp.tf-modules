# ---------------------------------------------------------------------------
# Default project for all autoscaler resources. Per-item overrides supported.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used when an autoscaler entry does not set project_id explicitly."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for regional autoscalers.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region used when an autoscaler entry does not set region explicitly."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels merged into module outputs.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Autoscaler definitions
#
# Each entry is either a regional autoscaler (set region, leave zone empty)
# or a zonal autoscaler (set zone, leave region empty).
#
# Signal priority (highest to lowest):
#   1. scaling_schedules  — explicit min_replicas during a time window
#   2. cpu_utilization    — average CPU across MIG instances
#   3. load_balancing_utilization — HTTP LB backend utilization fraction
#   4. metric             — custom Cloud Monitoring / Pub-Sub queue depth
# ---------------------------------------------------------------------------
variable "autoscalers" {
  description = "List of autoscaler configurations. Set region for a regional autoscaler or zone for a zonal autoscaler."
  type = list(object({
    key        = string
    create     = optional(bool, true)
    name       = string
    project_id = optional(string, "") # overrides var.project_id when set
    region     = optional(string, "") # set for regional autoscaler (overrides var.region)
    zone       = optional(string, "") # set for zonal autoscaler; leave empty for regional

    target = string # self-link or id of the Managed Instance Group to autoscale

    min_replicas    = number
    max_replicas    = number
    cooldown_period = optional(number, 60)   # seconds; wait after scaling before next evaluation
    mode            = optional(string, "ON") # ON | ONLY_UP | ONLY_SCALE_OUT | OFF

    # ── CPU Utilization ──────────────────────────────────────────────────────
    cpu_utilization = optional(object({
      target            = number                   # 0.0 – 1.0; e.g. 0.6 = scale at 60% CPU
      predictive_method = optional(string, "NONE") # NONE | OPTIMIZE_AVAILABILITY
    }), null)

    # ── HTTP Load Balancing Utilization ──────────────────────────────────────
    load_balancing_utilization = optional(object({
      target = number # 0.0 – 1.0; fraction of backend serving capacity
    }), null)

    # ── Custom / Pub-Sub / Cloud Monitoring Metrics ──────────────────────────
    metrics = optional(list(object({
      name                       = string
      filter                     = optional(string, "")      # resource.type filter for multi-source metrics
      target                     = optional(number, 0)       # 0 = not set; use single_instance_assignment instead
      type                       = optional(string, "GAUGE") # GAUGE | DELTA_PER_SECOND | DELTA_PER_MINUTE
      single_instance_assignment = optional(number, 0)       # scale so each VM handles this many units (e.g. Pub-Sub messages)
    })), [])

    # ── Scaling Schedules ────────────────────────────────────────────────────
    scaling_schedules = optional(list(object({
      name                  = string
      min_required_replicas = number
      schedule              = string # cron expression, e.g. "0 8 * * MON-FRI"
      time_zone             = optional(string, "UTC")
      duration_sec          = optional(number, 3600) # how long the schedule is active
      disabled              = optional(bool, false)
      description           = optional(string, "")
    })), [])

    # ── Scale-In Control ─────────────────────────────────────────────────────
    scale_in_control = optional(object({
      time_window_sec                = optional(number, 300) # rolling window for the limit
      max_scaled_in_replicas_fixed   = optional(number, 0)   # 0 = not set
      max_scaled_in_replicas_percent = optional(number, 0)   # 0 = not set; mutually exclusive with fixed
    }), null)
  }))
  default = []

  validation {
    condition     = length(distinct([for a in var.autoscalers : a.key])) == length(var.autoscalers)
    error_message = "autoscalers[*].key values must be unique."
  }

  validation {
    condition = alltrue([
      for a in var.autoscalers : contains(["ON", "ONLY_UP", "ONLY_SCALE_OUT", "OFF"], a.mode)
    ])
    error_message = "autoscalers[*].mode must be one of: ON, ONLY_UP, ONLY_SCALE_OUT, OFF."
  }

  validation {
    condition = alltrue([
      for a in var.autoscalers :
      trimspace(a.region) != "" || trimspace(a.zone) != ""
    ])
    error_message = "Each autoscaler entry must set either region (regional autoscaler) or zone (zonal autoscaler)."
  }

  validation {
    condition = alltrue([
      for a in var.autoscalers :
      !(trimspace(a.region) != "" && trimspace(a.zone) != "")
    ])
    error_message = "Each autoscaler entry must set region OR zone, not both."
  }
}
