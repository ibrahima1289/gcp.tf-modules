# ---------------------------------------------------------------------------
# Provider region.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider. Folder resources are global."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Fallback parent for folder creation.
# ---------------------------------------------------------------------------
variable "default_parent" {
  description = "Fallback parent for folders (organizations/<id> or folders/<id>)."
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
# Folders to create (supports multiple and nested folders).
# ---------------------------------------------------------------------------
variable "folders" {
  description = "List of folders to create."
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
    error_message = "Each folder requires a parent via parent, parent_folder_key, or wrapper default_parent."
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
    error_message = "folders.parent_folder_key must reference a top-level folder in the same wrapper. Multi-level nested folder chains should be applied in separate runs/modules."
  }
}

# ---------------------------------------------------------------------------
# Optional folder IAM members (additive).
# ---------------------------------------------------------------------------
variable "folder_iam_members" {
  description = "List of additive IAM grants at folder level."
  type = list(object({
    key        = string
    folder_key = string
    role       = string
    member     = string
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Optional folder OrgPolicy constraints.
# ---------------------------------------------------------------------------
variable "folder_policies" {
  description = "List of folder-level OrgPolicy v2 constraints."
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
}

# ---------------------------------------------------------------------------
# Optional folder logging sinks.
# ---------------------------------------------------------------------------
variable "folder_log_sinks" {
  description = "List of folder-level logging sinks."
  type = list(object({
    key              = string
    folder_key       = string
    name             = string
    destination      = string
    filter           = optional(string, "")
    include_children = optional(bool, true)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Optional folder essential contacts.
# ---------------------------------------------------------------------------
variable "folder_essential_contacts" {
  description = "List of folder-level essential contacts."
  type = list(object({
    key                     = string
    folder_key              = string
    email                   = string
    language_tag            = optional(string, "en")
    notification_categories = list(string)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Optional common labels/tags.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels/tags merged with created_date and managed_by metadata."
  type        = map(string)
  default     = {}
}
