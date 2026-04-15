variable "project_id" {
  description = "Default Google Cloud project ID. Used when no per-resource project is specified in service_accounts or custom_roles entries."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase alphanumeric characters and hyphens, starting with a letter)."
  }
}

variable "tags" {
  description = "Resource labels applied to all label-supporting resources. Merged with module defaults (managed_by, created_date)."
  type        = map(string)
  default     = {}
}

variable "service_accounts" {
  description = <<-EOT
    List of service accounts to create. Each entry requires a stable unique 'key' for for_each.

    Attributes:
      key          - (required) Unique stable identifier used as the for_each key.
      account_id   - (required) The account ID portion of the SA email (e.g. "my-sa").
      display_name - (optional) Human-readable display name.
      description  - (optional) Human-readable description.
      project_id   - (optional) Override project. Defaults to var.project_id.
      disabled     - (optional) Whether to disable the service account. Defaults to false.
      create       - (optional) Set to false to skip resource creation while keeping the entry in config. Defaults to true.
  EOT
  type = list(object({
    key          = string
    account_id   = string
    display_name = optional(string, "")
    description  = optional(string, "")
    project_id   = optional(string, "")
    disabled     = optional(bool, false)
    create       = optional(bool, true)
  }))
  default = []

  validation {
    condition     = length(distinct([for sa in var.service_accounts : sa.key])) == length(var.service_accounts)
    error_message = "Each service_accounts entry must have a unique 'key' value."
  }

  validation {
    condition     = alltrue([for sa in var.service_accounts : can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", sa.account_id))])
    error_message = "Each service account 'account_id' must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "custom_roles" {
  description = <<-EOT
    List of custom IAM roles to create at project or organization scope.

    Attributes:
      key         - (required) Unique stable identifier used as the for_each key.
      role_id     - (required) Role identifier (alphanumeric and underscores, max 64 chars).
      title       - (required) Human-readable title for the custom role.
      description - (optional) Human-readable description.
      permissions - (required) List of IAM permissions to grant.
      scope       - (optional) "project" or "organization". Defaults to "project".
      resource    - (optional) Project ID or Org ID override. Defaults to var.project_id for project scope.
      stage       - (optional) GA, BETA, ALPHA, DEPRECATED, DISABLED, or EAP. Defaults to "GA".
      create      - (optional) Set to false to skip resource creation while keeping the entry in config. Defaults to true.
  EOT
  type = list(object({
    key         = string
    role_id     = string
    title       = string
    description = optional(string, "")
    permissions = list(string)
    scope       = optional(string, "project")
    resource    = optional(string, "")
    stage       = optional(string, "GA")
    create      = optional(bool, true)
  }))
  default = []

  validation {
    condition     = length(distinct([for r in var.custom_roles : r.key])) == length(var.custom_roles)
    error_message = "Each custom_roles entry must have a unique 'key' value."
  }

  validation {
    condition     = alltrue([for r in var.custom_roles : contains(["project", "organization"], r.scope)])
    error_message = "Each custom_role 'scope' must be one of: project, organization."
  }

  validation {
    condition     = alltrue([for r in var.custom_roles : contains(["GA", "BETA", "ALPHA", "DEPRECATED", "DISABLED", "EAP"], r.stage)])
    error_message = "Each custom_role 'stage' must be one of: GA, BETA, ALPHA, DEPRECATED, DISABLED, EAP."
  }
}

variable "bindings" {
  description = <<-EOT
    List of authoritative IAM bindings at project, folder, or organization scope.

    IMPORTANT: Authoritative bindings replace ALL existing members for the specified role.
    Use var.members for additive semantics when sharing a role across multiple configurations.

    Attributes:
      key      - (required) Unique stable identifier used as the for_each key.
      scope    - (required) "project", "folder", or "organization".
      resource - (required) Project ID, folder numeric ID, or org numeric ID.
      role     - (required) IAM role (e.g. "roles/compute.viewer").
      members  - (required) List of member strings.
      create   - (optional) Set to false to skip resource creation while keeping the entry in config. Defaults to true.
  EOT
  type = list(object({
    key      = string
    scope    = string
    resource = string
    role     = string
    members  = list(string)
    create   = optional(bool, true)
  }))
  default = []

  validation {
    condition     = length(distinct([for b in var.bindings : b.key])) == length(var.bindings)
    error_message = "Each bindings entry must have a unique 'key' value."
  }

  validation {
    condition     = alltrue([for b in var.bindings : contains(["project", "folder", "organization"], b.scope)])
    error_message = "Each binding 'scope' must be one of: project, folder, organization."
  }
}

variable "members" {
  description = <<-EOT
    List of additive IAM member bindings at project, folder, or organization scope.

    Additive bindings add one member to a role without disturbing any existing members.
    Safe to use for shared predefined roles across multiple Terraform configurations.

    Attributes:
      key      - (required) Unique stable identifier used as the for_each key.
      scope    - (required) "project", "folder", or "organization".
      resource - (required) Project ID, folder numeric ID, or org numeric ID.
      role     - (required) IAM role to grant.
      member   - (required) Single member string.
      create   - (optional) Set to false to skip resource creation while keeping the entry in config. Defaults to true.
  EOT
  type = list(object({
    key      = string
    scope    = string
    resource = string
    role     = string
    member   = string
    create   = optional(bool, true)
  }))
  default = []

  validation {
    condition     = length(distinct([for m in var.members : m.key])) == length(var.members)
    error_message = "Each members entry must have a unique 'key' value."
  }

  validation {
    condition     = alltrue([for m in var.members : contains(["project", "folder", "organization"], m.scope)])
    error_message = "Each member 'scope' must be one of: project, folder, organization."
  }
}
