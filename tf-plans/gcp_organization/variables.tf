# ---------------------------------------------------------------------------
# Organization lookup — provide exactly one of org_domain or org_id.
# ---------------------------------------------------------------------------

variable "org_domain" {
  description = "Primary domain of the Google Cloud Organization (e.g., example.com). Provide this OR org_id, not both."
  type        = string
  default     = ""
}

variable "org_id" {
  description = "Numeric Google Cloud Organization ID (e.g., 123456789012). Provide this OR org_domain, not both."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Provider region.
# ---------------------------------------------------------------------------

variable "region" {
  description = "Default region for the Google provider. Organization-level resources are global."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common labels merged with the wrapper's created_date stamp.
# ---------------------------------------------------------------------------

variable "labels" {
  description = "Common labels merged with wrapper created_date stamp and passed to the module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# IAM members (additive) at the organization level.
# ---------------------------------------------------------------------------

variable "iam_members" {
  description = "List of additive IAM role grants at the organization level."
  type = list(object({
    key    = string # Unique key for stable for_each identity.
    role   = string # e.g., "roles/viewer"
    member = string # e.g., "group:admins@example.com"
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Organization policies (OrgPolicy v2 API).
# ---------------------------------------------------------------------------

variable "org_policies" {
  description = "List of organization-level OrgPolicy v2 constraint policies."
  type = list(object({
    key            = string
    constraint     = string
    type           = optional(string, "boolean")
    enforce        = optional(string, "TRUE")
    allow_all      = optional(bool, false)
    deny_all       = optional(bool, false)
    allowed_values = optional(list(string), [])
    denied_values  = optional(list(string), [])
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Organization-level log sinks.
# ---------------------------------------------------------------------------

variable "log_sinks" {
  description = "List of organization-level log sinks for centralized log export."
  type = list(object({
    key              = string
    name             = string
    destination      = string # e.g., "storage.googleapis.com/my-bucket"
    filter           = optional(string, "")
    include_children = optional(bool, true)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Essential contacts at the organization level.
# ---------------------------------------------------------------------------

variable "essential_contacts" {
  description = "List of essential contacts registered at the organization level."
  type = list(object({
    key                     = string
    email                   = string
    language_tag            = optional(string, "en")
    notification_categories = list(string)
  }))
  default = []
}
