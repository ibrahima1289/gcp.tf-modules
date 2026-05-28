# variables.tf

# ---------------------------------------------------------------------------
# Default project for DNS resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID for all DNS zone definitions."
  type        = string
}

# ---------------------------------------------------------------------------
# Region variable for interface consistency; Cloud DNS is global.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Region kept for interface consistency. Cloud DNS is a global service."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common tags merged with generated governance metadata into each zone's labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many Cloud DNS zone definitions.
# ---------------------------------------------------------------------------
variable "zones" {
  description = "List of DNS managed zone configurations including nested record sets."
  type = list(object({
    key         = string
    name        = string
    dns_name    = string
    description = optional(string, "")
    create      = optional(bool, true)
    project_id  = optional(string, "")

    zone_type            = optional(string, "public")
    dnssec_enabled       = optional(bool, false)
    dnssec_non_existence = optional(string, "nsec3")

    private_visibility_networks = optional(list(string), [])

    forwarding_targets = optional(list(object({
      ipv4_address    = string
      forwarding_path = optional(string, "default")
    })), [])

    peering_target_network = optional(string, "")
    labels                 = optional(map(string), {})

    records = optional(list(object({
      key     = string
      name    = string
      type    = string
      ttl     = optional(number, 300)
      create  = optional(bool, true)
      rrdatas = optional(list(string), [])

      routing_policy = optional(object({
        enabled            = bool
        type               = optional(string, "WRR")
        enable_geo_fencing = optional(bool, false)
        wrr_targets = optional(list(object({
          weight  = number
          rrdatas = list(string)
        })), [])
        geo_targets = optional(list(object({
          location = string
          rrdatas  = list(string)
        })), [])
        }), {
        enabled            = false
        type               = "WRR"
        enable_geo_fencing = false
        wrr_targets        = []
        geo_targets        = []
      })
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for z in var.zones : z.key])) == length(var.zones)
    error_message = "zones[*].key values must be unique."
  }
}
