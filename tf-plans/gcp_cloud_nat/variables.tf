# variables.tf

# ---------------------------------------------------------------------------
# Default project for NAT resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID for NAT definitions."
  type        = string
}

# ---------------------------------------------------------------------------
# Default region for NAT resources.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region for NAT definitions."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance tags.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common tags merged with generated metadata labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud NAT definitions.
# ---------------------------------------------------------------------------
variable "nats" {
  description = "List of Cloud NAT configurations to create."
  type = list(object({
    key  = string
    name = string

    project_id = optional(string, "")
    region     = optional(string, "")

    create_router             = optional(bool, false)
    router                    = optional(string, "")
    router_name               = optional(string, "")
    router_description        = optional(string, "")
    network                   = optional(string, "")
    router_asn                = optional(number, 64514)
    router_keepalive_interval = optional(number, 20)

    nat_ip_allocate_option = optional(string, "AUTO_ONLY")
    nat_ips                = optional(list(string), [])
    drain_nat_ips          = optional(list(string), [])

    source_subnetwork_ip_ranges_to_nat = optional(string, "ALL_SUBNETWORKS_ALL_IP_RANGES")
    subnetworks = optional(list(object({
      name                     = string
      source_ip_ranges_to_nat  = set(string)
      secondary_ip_range_names = optional(list(string), [])
    })), [])

    enable_endpoint_independent_mapping = optional(bool, true)
    enable_dynamic_port_allocation      = optional(bool, false)
    min_ports_per_vm                    = optional(number, 64)
    max_ports_per_vm                    = optional(number, 4096)
    udp_idle_timeout_sec                = optional(number, 30)
    icmp_idle_timeout_sec               = optional(number, 30)
    tcp_established_idle_timeout_sec    = optional(number, 1200)
    tcp_transitory_idle_timeout_sec     = optional(number, 30)
    tcp_time_wait_timeout_sec           = optional(number, 120)

    log_config_enable = optional(bool, false)
    log_config_filter = optional(string, "ERRORS_ONLY")
  }))
  default = []

  validation {
    condition     = length(distinct([for n in var.nats : n.key])) == length(var.nats)
    error_message = "nats[*].key values must be unique."
  }
}
