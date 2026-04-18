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

  validation {
    condition     = var.org_id == "" || can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id must be a numeric string (e.g., '123456789012')."
  }
}

# ---------------------------------------------------------------------------
# Region — used by the Google provider configuration.
# Organization-level resources are global; this is required for provider setup.
# ---------------------------------------------------------------------------

variable "region" {
  description = "Default region passed to the Google provider. Organization-level resources are global but a region is required for provider configuration."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# IAM members (additive) at the organization level.
# Uses google_organization_iam_member to additively grant roles without
# overwriting existing principals that are not managed by this module.
# ---------------------------------------------------------------------------

variable "iam_members" {
  description = "List of additive IAM role grants at the organization level. Each entry grants a single role to a single member."
  type = list(object({
    key    = string # Unique key for stable for_each identity.
    role   = string # e.g., "roles/viewer", "roles/resourcemanager.organizationAdmin"
    member = string # e.g., "user:admin@example.com", "group:sec@example.com", "serviceAccount:sa@project.iam.gserviceaccount.com"
  }))
  default = []

  validation {
    condition     = length(distinct([for m in var.iam_members : m.key])) == length(var.iam_members)
    error_message = "iam_members keys must be unique."
  }
}

# ---------------------------------------------------------------------------
# Organization policies (OrgPolicy v2 API).
# Supports boolean constraints (enforce/un-enforce) and list constraints
# (allow all, deny all, or explicit allowed/denied value sets).
# ---------------------------------------------------------------------------

variable "org_policies" {
  description = "List of organization-level constraint policies to apply via the OrgPolicy v2 API."
  type = list(object({
    key            = string                      # Unique key for stable for_each identity.
    constraint     = string                      # Constraint name, e.g., "compute.disableSerialPortAccess".
    type           = optional(string, "boolean") # "boolean" or "list".
    enforce        = optional(string, "TRUE")    # For boolean type: "TRUE" to enforce, "FALSE" to un-enforce.
    allow_all      = optional(bool, false)       # For list type: allow all values.
    deny_all       = optional(bool, false)       # For list type: deny all values.
    allowed_values = optional(list(string), [])  # For list type: specific values to allow.
    denied_values  = optional(list(string), [])  # For list type: specific values to deny.
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.org_policies : p.key])) == length(var.org_policies)
    error_message = "org_policies keys must be unique."
  }

  validation {
    condition     = alltrue([for p in var.org_policies : contains(["boolean", "list"], p.type)])
    error_message = "org_policies.type must be 'boolean' or 'list'."
  }

  validation {
    condition     = alltrue([for p in var.org_policies : p.type != "boolean" || contains(["TRUE", "FALSE"], p.enforce)])
    error_message = "org_policies.enforce must be 'TRUE' or 'FALSE' for boolean type policies."
  }
}

# ---------------------------------------------------------------------------
# Organization-level log sinks.
# ---------------------------------------------------------------------------

variable "log_sinks" {
  description = "List of organization-level log sinks for centralized log export."
  type = list(object({
    key              = string               # Unique key for stable for_each identity.
    name             = string               # Sink resource name.
    destination      = string               # e.g., "storage.googleapis.com/my-bucket", "bigquery.googleapis.com/projects/PROJECT/datasets/DATASET".
    filter           = optional(string, "") # Log filter expression; empty string captures all logs.
    include_children = optional(bool, true) # Route logs from all child projects and folders.
  }))
  default = []

  validation {
    condition     = length(distinct([for s in var.log_sinks : s.key])) == length(var.log_sinks)
    error_message = "log_sinks keys must be unique."
  }
}

# ---------------------------------------------------------------------------
# Essential contacts at the organization level.
# ---------------------------------------------------------------------------

variable "essential_contacts" {
  description = "List of essential contacts registered at the organization level for Google Cloud notifications."
  type = list(object({
    key                     = string                 # Unique key for stable for_each identity.
    email                   = string                 # Contact email address.
    language_tag            = optional(string, "en") # BCP-47 language tag (e.g., "en", "fr", "de").
    notification_categories = list(string)           # One or more of: BILLING, LEGAL, PRODUCT_UPDATES, SECURITY, SUSPENSION, TECHNICAL, TECHNICAL_INCIDENTS.
  }))
  default = []

  validation {
    condition     = length(distinct([for c in var.essential_contacts : c.key])) == length(var.essential_contacts)
    error_message = "essential_contacts keys must be unique."
  }

  validation {
    condition = alltrue([
      for c in var.essential_contacts : alltrue([
        for cat in c.notification_categories :
        contains(["ALL", "BILLING", "LEGAL", "PRODUCT_UPDATES", "SECURITY", "SUSPENSION", "TECHNICAL", "TECHNICAL_INCIDENTS"], cat)
      ])
    ])
    error_message = "essential_contacts.notification_categories must be one or more of: ALL, BILLING, LEGAL, PRODUCT_UPDATES, SECURITY, SUSPENSION, TECHNICAL, TECHNICAL_INCIDENTS."
  }
}

# ---------------------------------------------------------------------------
# Common labels — stored in locals for documentation and potential future
# use. Organization-level resources do not support labels directly.
# ---------------------------------------------------------------------------

variable "labels" {
  description = "Common labels for module resources. Note: most org-level GCP resources do not support labels natively; these are stored in locals for reference."
  type        = map(string)
  default     = {}
}
