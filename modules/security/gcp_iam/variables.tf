variable "project_id" {
  description = "Default Google Cloud project ID. Used when no per-resource project is specified in service_accounts or custom_roles entries."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase alphanumeric characters and hyphens, starting with a letter)."
  }
}

variable "tags" {
  description = "Resource labels applied to all label-supporting resources managed by this module."
  type        = map(string)
  default     = {}
}

variable "service_accounts" {
  description = <<-EOT
    List of service accounts to create. Each entry requires a stable unique 'key' for for_each.

    Attributes:
      key          - (required) Unique stable identifier used as the for_each key.
      account_id   - (required) The account ID portion of the service account email (e.g. "my-sa" becomes "my-sa@project.iam.gserviceaccount.com").
      display_name - (optional) Human-readable display name. Defaults to empty (no display name set).
      description  - (optional) Human-readable description. Defaults to empty (no description set).
      project_id   - (optional) Project to create the service account in. Defaults to var.project_id.
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
    List of custom IAM roles to create. Each entry requires a stable unique 'key' for for_each.

    Attributes:
      key         - (required) Unique stable identifier used as the for_each key.
      role_id     - (required) The role identifier (alphanumeric and underscores, max 64 chars).
      title       - (required) Human-readable title for the custom role.
      description - (optional) Human-readable description. Defaults to empty (no description set).
      permissions - (required) List of IAM permissions to grant with this role.
      scope       - (optional) Target scope: "project" or "organization". Defaults to "project".
      resource    - (optional) Project ID or Org ID override. Defaults to var.project_id for project scope.
      stage       - (optional) Launch stage: GA, BETA, ALPHA, DEPRECATED, DISABLED, or EAP. Defaults to "GA".
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

    IMPORTANT: Authoritative bindings replace ALL existing members for the specified role on the
    target resource. Members not listed here will be removed. Use var.members for shared roles
    where you need additive-only semantics.

    Attributes:
      key      - (required) Unique stable identifier used as the for_each key.
      scope    - (required) Target scope: "project", "folder", or "organization".
      resource - (required) Resource ID: project ID, folder numeric ID, or organization numeric ID.
      role     - (required) IAM role to bind (e.g. "roles/compute.viewer").
      members  - (required) List of members in the form "user:", "serviceAccount:", "group:", or "domain:".
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

    Additive bindings add a single member to a role without disturbing any existing members.
    Safe to use for shared predefined roles across multiple Terraform configurations.

    Attributes:
      key      - (required) Unique stable identifier used as the for_each key.
      scope    - (required) Target scope: "project", "folder", or "organization".
      resource - (required) Resource ID: project ID, folder numeric ID, or organization numeric ID.
      role     - (required) IAM role to grant (e.g. "roles/storage.objectViewer").
      member   - (required) Single member string (e.g. "serviceAccount:sa@project.iam.gserviceaccount.com").
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
