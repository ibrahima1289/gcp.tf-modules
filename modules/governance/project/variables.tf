# variables.tf

variable "region" {
  description = "Default region passed to the Google provider."
  type        = string
  default     = "us-central1"
}

variable "project_id" {
  description = "Unique identifier for the project"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a letter, and contain lowercase letters, digits, or hyphens."
  }
}

variable "name" {
  description = "Name of the project"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID"
  type        = string
  default     = ""
}

variable "org_id" {
  description = "Organization ID for the project"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID for the project parent. Use either org_id or folder_id."
  type        = string
  default     = ""

  # validation {
  #   condition = (
  #     (trimspace(var.org_id) != "" && trimspace(var.folder_id) == "") ||
  #     (trimspace(var.org_id) == "" && trimspace(var.folder_id) != "")
  #   )
  #   error_message = "Set exactly one of org_id or folder_id."
  # }
}

variable "enable_services" {
  description = "List of services to enable"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Key-value pairs for labels"
  type        = map(string)
  default     = {}
}

variable "prevent_destroy" {
  description = "Protect project from accidental deletion."
  type        = bool
  default     = true
}

variable "additional_projects" {
  description = "Optional additional projects to create in the same module call. Each project can target org_id or folder_id."
  type = list(object({
    project_id      = string
    name            = string
    billing_account = optional(string, "")
    org_id          = optional(string, "")
    folder_id       = optional(string, "")
    enable_services = optional(list(string), [])
    labels          = optional(map(string), {})
    prevent_destroy = optional(bool)
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.additional_projects : p.project_id])) == length(var.additional_projects)
    error_message = "additional_projects.project_id values must be unique."
  }

  validation {
    condition = alltrue([
      for p in var.additional_projects : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))
    ])
    error_message = "Each additional_projects.project_id must be 6-30 chars, start with a letter, and contain lowercase letters, digits, or hyphens."
  }

  validation {
    condition = alltrue([
      for p in var.additional_projects : (
        (trimspace(try(p.org_id, "")) != "" && trimspace(try(p.folder_id, "")) == "") ||
        (trimspace(try(p.org_id, "")) == "" && trimspace(try(p.folder_id, "")) != "")
      )
    ])
    error_message = "Each additional_projects item must set exactly one of org_id or folder_id."
  }

  validation {
    condition     = !contains([for p in var.additional_projects : p.project_id], var.project_id)
    error_message = "additional_projects cannot contain the same project_id as project_id."
  }
}
