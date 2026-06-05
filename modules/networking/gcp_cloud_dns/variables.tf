# variables.tf

# ---------------------------------------------------------------------------
# Default project for DNS resources. Per-zone project overrides are supported.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "Default GCP project ID used when a zone entry does not set project_id explicitly."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Region is accepted for interface consistency with other modules.
# Cloud DNS is a global service and does not use region directly.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Region variable kept for module interface consistency. Cloud DNS is global and does not use this value directly."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common tags applied to all zone labels.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date into every zone's label map."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# One or many DNS zone definitions, each with optional record sets.
# ---------------------------------------------------------------------------
variable "zones" {
  description = "List of DNS managed zone configurations. Each entry creates one zone and its record sets."
  type = list(object({
    key         = string # Unique stable key for for_each
    name        = string # DNS zone resource name (lowercase, no dots)
    dns_name    = string # DNS name with trailing dot, e.g. "example.com."
    description = optional(string, "")
    create      = optional(bool, true)

    # Per-zone project override; falls back to var.project_id when empty.
    project_id = optional(string, "")

    # Zone type determines visibility and sub-config blocks.
    zone_type = optional(string, "public") # public | private | forwarding | peering

    # DNSSEC options (public zones only).
    dnssec_enabled       = optional(bool, false)
    dnssec_non_existence = optional(string, "nsec3") # nsec | nsec3

    # VPC network self-links for private / forwarding / peering zones.
    private_visibility_networks = optional(list(string), [])

    # Upstream resolver targets for forwarding zones.
    forwarding_targets = optional(list(object({
      ipv4_address    = string
      forwarding_path = optional(string, "default") # default | private
    })), [])

    # Target VPC network for peering zones.
    peering_target_network = optional(string, "")

    # Additional labels merged with common tags.
    labels = optional(map(string), {})

    # ---------------------------------------------------------------------------
    # Record sets nested under this zone.
    # ---------------------------------------------------------------------------
    records = optional(list(object({
      key     = string # Unique stable key within this zone
      name    = string # Full DNS name with trailing dot, e.g. "api.example.com."
      type    = string # A | AAAA | CNAME | MX | TXT | NS | PTR | SRV | CAA
      ttl     = optional(number, 300)
      create  = optional(bool, true)
      rrdatas = optional(list(string), []) # Simple record data; empty when routing_policy.enabled = true

      # Routing policy for WRR or GEO-based traffic distribution.
      # Set enabled = true to activate; leave false for simple records.
      routing_policy = optional(object({
        enabled            = bool
        type               = optional(string, "WRR") # WRR | GEO
        enable_geo_fencing = optional(bool, false)   # GEO only: restrict to matched regions
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

  validation {
    condition     = length(distinct([for z in var.zones : z.name])) == length(var.zones)
    error_message = "zones[*].name values must be unique."
  }

  validation {
    condition = alltrue([
      for z in var.zones : contains(["public", "private", "forwarding", "peering"], z.zone_type)
    ])
    error_message = "zones[*].zone_type must be public, private, forwarding, or peering."
  }

  validation {
    condition = alltrue([
      for z in var.zones : contains(["nsec", "nsec3"], z.dnssec_non_existence)
    ])
    error_message = "zones[*].dnssec_non_existence must be nsec or nsec3."
  }

  validation {
    condition = alltrue([
      for z in var.zones : z.zone_type != "forwarding" || length(z.forwarding_targets) > 0
    ])
    error_message = "Forwarding zones must define at least one forwarding_targets entry."
  }

  validation {
    condition = alltrue([
      for z in var.zones : z.zone_type != "peering" || trimspace(z.peering_target_network) != ""
    ])
    error_message = "Peering zones must set peering_target_network to the target VPC network URL."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : [
          contains(["A", "AAAA", "CNAME", "MX", "TXT", "NS", "PTR", "SRV", "CAA", "SOA"], r.type)
        ]
      ]
    ]))
    error_message = "records[*].type must be one of: A, AAAA, CNAME, MX, TXT, NS, PTR, SRV, CAA, SOA."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : [
          !r.routing_policy.enabled || contains(["WRR", "GEO"], r.routing_policy.type)
        ]
      ]
    ]))
    error_message = "records[*].routing_policy.type must be WRR or GEO when routing_policy.enabled = true."
  }
}
