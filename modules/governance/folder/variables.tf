# ---------------------------------------------------------------------------
# Provider region.
# Folder-level resources are global, but provider config requires a region.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider. Folder-level resources are global but a region is required for provider configuration."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Module-wide fallback parent for folders that do not define parent fields.
# Example: organizations/123456789012
# ---------------------------------------------------------------------------
variable "default_parent" {
  description = "Fallback parent for folder creation (organizations/<id> or folders/<id>). Used when a folder object does not specify parent or parent_folder_key."
  type        = string
  default     = ""

  validation {
    condition = (
      var.default_parent == "" ||
      can(regex("^organizations/[0-9]+$", var.default_parent)) ||
      can(regex("^folders/[0-9]+$", var.default_parent))
    )
    error_message = "default_parent must be empty or in format organizations/<numeric_id> or folders/<numeric_id>."
  }
}

# ---------------------------------------------------------------------------
# Folders to create. Supports multiple and nested folder creation.
# ---------------------------------------------------------------------------
variable "folders" {
  description = "List of folders to create. Supports top-level or nested folders via parent or parent_folder_key."
  type = list(object({
    key               = string
    display_name      = string
    parent            = optional(string, "")
    parent_folder_key = optional(string, "")
  }))
  default = []

  validation {
    condition     = length(distinct([for f in var.folders : f.key])) == length(var.folders)
    error_message = "folders keys must be unique."
  }

  validation {
    condition = alltrue([
      for f in var.folders : trimspace(f.display_name) != ""
    ])
    error_message = "folders.display_name cannot be empty."
  }

  validation {
    condition = alltrue([
      for f in var.folders : !(trimspace(f.parent) != "" && trimspace(f.parent_folder_key) != "")
    ])
    error_message = "For each folders item, use only one of parent or parent_folder_key."
  }

  validation {
    condition = alltrue([
      for f in var.folders : (
        trimspace(f.parent) != "" ||
        trimspace(f.parent_folder_key) != "" ||
        trimspace(var.default_parent) != ""
      )
    ])
    error_message = "Each folder requires a parent via parent, parent_folder_key, or module default_parent."
  }

  validation {
    condition = alltrue([
      for f in var.folders : (
        trimspace(f.parent) == "" ||
        can(regex("^organizations/[0-9]+$", f.parent)) ||
        can(regex("^folders/[0-9]+$", f.parent))
      )
    ])
    error_message = "folders.parent must be empty or in format organizations/<numeric_id> or folders/<numeric_id>."
  }

  validation {
    condition = alltrue([
      for f in var.folders : (
        trimspace(f.parent_folder_key) == "" ||
        contains([for x in var.folders : x.key], f.parent_folder_key)
      )
    ])
    error_message = "folders.parent_folder_key must reference an existing folders.key in the same input list."
  }

  validation {
    condition = alltrue([
      for f in var.folders : (
        trimspace(f.parent_folder_key) == "" ||
        f.parent_folder_key != f.key
      )
    ])
    error_message = "folders.parent_folder_key cannot reference the same folder key."
  }

  validation {
    condition = alltrue([
      for f in var.folders : (
        trimspace(f.parent_folder_key) == "" ||
        length([
          for parent in var.folders : parent.key
          if parent.key == f.parent_folder_key && trimspace(parent.parent_folder_key) == ""
        ]) == 1
      )
    ])
    error_message = "folders.parent_folder_key must reference a top-level folder in the same module call. Multi-level nested folder chains should be applied in separate runs/modules."
  }
}

# ---------------------------------------------------------------------------
# Folder IAM members (additive).
# ---------------------------------------------------------------------------
variable "folder_iam_members" {
  description = "List of additive IAM role grants at folder level."
  type = list(object({
    key        = string
    folder_key = string
    role       = string
    member     = string
  }))
  default = []

  validation {
    condition     = length(distinct([for m in var.folder_iam_members : m.key])) == length(var.folder_iam_members)
    error_message = "folder_iam_members keys must be unique."
  }

  validation {
    condition = alltrue([
      for m in var.folder_iam_members : contains([for f in var.folders : f.key], m.folder_key)
    ])
    error_message = "Each folder_iam_members.folder_key must reference an existing folders.key."
  }
}

# ---------------------------------------------------------------------------
# Folder OrgPolicy v2 constraints.
# ---------------------------------------------------------------------------
variable "folder_policies" {
  description = "List of folder-level OrgPolicy v2 constraint policies."
  type = list(object({
    key            = string
    folder_key     = string
    constraint     = string
    type           = optional(string, "boolean")
    enforce        = optional(string, "TRUE")
    allow_all      = optional(bool, false)
    deny_all       = optional(bool, false)
    allowed_values = optional(list(string), [])
    denied_values  = optional(list(string), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.folder_policies : p.key])) == length(var.folder_policies)
    error_message = "folder_policies keys must be unique."
  }

  validation {
    condition = alltrue([
      for p in var.folder_policies : contains([for f in var.folders : f.key], p.folder_key)
    ])
    error_message = "Each folder_policies.folder_key must reference an existing folders.key."
  }

  validation {
    condition     = alltrue([for p in var.folder_policies : contains(["boolean", "list"], p.type)])
    error_message = "folder_policies.type must be 'boolean' or 'list'."
  }

  validation {
    condition     = alltrue([for p in var.folder_policies : p.type != "boolean" || contains(["TRUE", "FALSE"], p.enforce)])
    error_message = "folder_policies.enforce must be 'TRUE' or 'FALSE' for boolean type policies."
  }

  validation {
    condition = alltrue([
      for p in var.folder_policies : (
        p.type != "list" ||
        p.allow_all ||
        p.deny_all ||
        length(p.allowed_values) > 0 ||
        length(p.denied_values) > 0
      )
    ])
    error_message = "For list type folder_policies, specify at least one of allow_all, deny_all, allowed_values, or denied_values."
  }

  validation {
    condition = alltrue([
      for p in var.folder_policies : !(p.type == "list" && p.allow_all && p.deny_all)
    ])
    error_message = "For list type folder_policies, allow_all and deny_all cannot both be true."
  }
}

# ---------------------------------------------------------------------------
# Folder log sinks.
# ---------------------------------------------------------------------------
variable "folder_log_sinks" {
  description = "List of folder-level log sinks for centralized log export."
  type = list(object({
    key              = string
    folder_key       = string
    name             = string
    destination      = string
    filter           = optional(string, "")
    include_children = optional(bool, true)
  }))
  default = []

  validation {
    condition     = length(distinct([for s in var.folder_log_sinks : s.key])) == length(var.folder_log_sinks)
    error_message = "folder_log_sinks keys must be unique."
  }

  validation {
    condition = alltrue([
      for s in var.folder_log_sinks : contains([for f in var.folders : f.key], s.folder_key)
    ])
    error_message = "Each folder_log_sinks.folder_key must reference an existing folders.key."
  }
}

# ---------------------------------------------------------------------------
# Folder essential contacts.
# ---------------------------------------------------------------------------
variable "folder_essential_contacts" {
  description = "List of essential contacts registered at folder scope."
  type = list(object({
    key                     = string
    folder_key              = string
    email                   = string
    language_tag            = optional(string, "en")
    notification_categories = list(string)
  }))
  default = []

  validation {
    condition     = length(distinct([for c in var.folder_essential_contacts : c.key])) == length(var.folder_essential_contacts)
    error_message = "folder_essential_contacts keys must be unique."
  }

  validation {
    condition = alltrue([
      for c in var.folder_essential_contacts : contains([for f in var.folders : f.key], c.folder_key)
    ])
    error_message = "Each folder_essential_contacts.folder_key must reference an existing folders.key."
  }

  validation {
    condition = alltrue([
      for c in var.folder_essential_contacts : alltrue([
        for cat in c.notification_categories :
        contains(["ALL", "BILLING", "LEGAL", "PRODUCT_UPDATES", "SECURITY", "SUSPENSION", "TECHNICAL", "TECHNICAL_INCIDENTS"], cat)
      ])
    ])
    error_message = "folder_essential_contacts.notification_categories must be one or more of: ALL, BILLING, LEGAL, PRODUCT_UPDATES, SECURITY, SUSPENSION, TECHNICAL, TECHNICAL_INCIDENTS."
  }
}

# ---------------------------------------------------------------------------
# Common labels for metadata/context in locals.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels stored in locals for metadata/reference."
  type        = map(string)
  default     = {}
}
