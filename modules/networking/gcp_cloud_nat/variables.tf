# variables.tf

# ---------------------------------------------------------------------------
# Default project for NAT resources. Per-NAT project overrides are supported.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used when a NAT item does not set project_id explicitly."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region for NAT resources. Per-NAT region overrides are supported.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region used when a NAT item does not set region explicitly."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common tags metadata for governance. Cloud NAT resources do not support
# labels directly, so tags are exposed in outputs for consistency.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance tags merged with module-generated metadata (managed_by, created_date)."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud NAT definitions.
# ---------------------------------------------------------------------------
variable "nats" {
  description = "List of Cloud NAT configurations. Each item creates one NAT and can optionally create its router."
  type = list(object({
    key  = string
    name = string

    # Placement overrides
    project_id = optional(string, "")
    region     = optional(string, "")

    # Router options
    create_router             = optional(bool, false)
    router                    = optional(string, "")
    router_name               = optional(string, "")
    router_description        = optional(string, "")
    network                   = optional(string, "")
    router_asn                = optional(number, 64514)
    router_keepalive_interval = optional(number, 20)

    # NAT IP options
    nat_ip_allocate_option = optional(string, "AUTO_ONLY")
    nat_ips                = optional(list(string), [])
    drain_nat_ips          = optional(list(string), [])

    # NAT scope options
    source_subnetwork_ip_ranges_to_nat = optional(string, "ALL_SUBNETWORKS_ALL_IP_RANGES")
    subnetworks = optional(list(object({
      name                     = string
      source_ip_ranges_to_nat  = set(string)
      secondary_ip_range_names = optional(list(string), [])
    })), [])

    # Port and timeout controls
    enable_endpoint_independent_mapping = optional(bool, true)
    enable_dynamic_port_allocation      = optional(bool, false)
    min_ports_per_vm                    = optional(number, 64)
    max_ports_per_vm                    = optional(number, 4096)
    udp_idle_timeout_sec                = optional(number, 30)
    icmp_idle_timeout_sec               = optional(number, 30)
    tcp_established_idle_timeout_sec    = optional(number, 1200)
    tcp_transitory_idle_timeout_sec     = optional(number, 30)
    tcp_time_wait_timeout_sec           = optional(number, 120)

    # Logging
    log_config_enable = optional(bool, false)
    log_config_filter = optional(string, "ERRORS_ONLY")
  }))
  default = []

  validation {
    condition     = length(distinct([for n in var.nats : n.key])) == length(var.nats)
    error_message = "nats[*].key values must be unique."
  }

  validation {
    condition     = length(distinct([for n in var.nats : n.name])) == length(var.nats)
    error_message = "nats[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for n in var.nats : contains(["AUTO_ONLY", "MANUAL_ONLY"], n.nat_ip_allocate_option)
    ])
    error_message = "Each nats[*].nat_ip_allocate_option must be AUTO_ONLY or MANUAL_ONLY."
  }

  validation {
    condition = alltrue([
      for n in var.nats : contains([
        "ALL_SUBNETWORKS_ALL_IP_RANGES",
        "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES",
        "LIST_OF_SUBNETWORKS"
      ], n.source_subnetwork_ip_ranges_to_nat)
    ])
    error_message = "Each nats[*].source_subnetwork_ip_ranges_to_nat must be ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, or LIST_OF_SUBNETWORKS."
  }

  validation {
    condition = alltrue([
      for n in var.nats : n.nat_ip_allocate_option != "MANUAL_ONLY" || length(n.nat_ips) > 0
    ])
    error_message = "When nat_ip_allocate_option is MANUAL_ONLY, nat_ips must contain at least one static IP self-link."
  }

  validation {
    condition = alltrue([
      for n in var.nats : n.source_subnetwork_ip_ranges_to_nat != "LIST_OF_SUBNETWORKS" || length(n.subnetworks) > 0
    ])
    error_message = "When source_subnetwork_ip_ranges_to_nat is LIST_OF_SUBNETWORKS, subnetworks must contain at least one entry."
  }

  validation {
    condition = alltrue([
      for n in var.nats : !n.create_router || trimspace(n.network) != ""
    ])
    error_message = "When create_router is true, network must be provided."
  }

  validation {
    condition = alltrue([
      for n in var.nats : n.create_router || trimspace(n.router) != ""
    ])
    error_message = "When create_router is false, router must be provided."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nats : [
        for s in n.subnetworks : [
          for v in s.source_ip_ranges_to_nat : contains(["ALL_IP_RANGES", "PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"], v)
        ]
      ]
    ]))
    error_message = "Each subnetworks[*].source_ip_ranges_to_nat value must be ALL_IP_RANGES, PRIMARY_IP_RANGE, or LIST_OF_SECONDARY_IP_RANGES."
  }

  validation {
    condition = alltrue([
      for n in var.nats : contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], n.log_config_filter)
    ])
    error_message = "Each nats[*].log_config_filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}
