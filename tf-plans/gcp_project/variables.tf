# ---------------------------------------------------------------------------
# Provider region.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default region passed to the Google provider."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common labels merged into every project.
# ---------------------------------------------------------------------------
variable "labels" {
  description = "Common labels merged with per-project labels."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Accidental deletion guard.
# ---------------------------------------------------------------------------
variable "prevent_destroy" {
  description = "Protect projects from accidental deletion."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# One or many projects to create.
# ---------------------------------------------------------------------------
variable "projects" {
  description = "List of projects to create. Supports one or multiple project definitions."
  type = list(object({
    project_id      = string
    name            = string
    billing_account = optional(string, "")
    org_id          = optional(string, "")
    folder_id       = optional(string, "")
    enable_services = optional(list(string), [])
    labels          = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length(distinct([for p in var.projects : p.project_id])) == length(var.projects)
    error_message = "projects.project_id values must be unique."
  }

  # validation {
  #   condition = alltrue([
  #     for p in var.projects : (trimspace(try(p.org_id, "")) != "") != (trimspace(try(p.folder_id, "")) != "")
  #   ])
  #   error_message = "Each projects item must set exactly one of org_id or folder_id."
  # }
}
