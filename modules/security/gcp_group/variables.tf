variable "customer_id" {
  description = "Cloud Identity or Workspace customer ID (e.g. 'C0xxxxxxx'). All groups belong to this tenant."
  type        = string

  validation {
    condition     = can(regex("^C[0-9a-z]+$", var.customer_id))
    error_message = "customer_id must start with 'C' followed by alphanumeric characters (e.g. 'C01ab2cd3')."
  }
}

variable "tags" {
  description = "Common governance tags exposed in module outputs (managed_by, created_date, and user-supplied key/value pairs)."
  type        = map(string)
  default     = {}
}

variable "groups" {
  description = "List of Cloud Identity group configurations. Each item creates one group and its memberships."
  type = list(object({
    key                  = string # unique stable key for for_each
    email                = string # canonical group email (GroupKey)
    display_name         = optional(string, "")
    description          = optional(string, "")
    labels               = optional(map(string), { "cloudidentity.googleapis.com/groups.discussion_forum" = "" }) # at least one required
    initial_group_config = optional(string, "EMPTY")                                                              # EMPTY | WITH_INITIAL_OWNER
    create               = optional(bool, true)
    members = optional(list(object({
      key          = string                             # unique stable key scoped to the parent group
      member_email = string                             # user, SA, or nested group email
      roles        = optional(list(string), ["MEMBER"]) # MEMBER | MANAGER | OWNER
      create       = optional(bool, true)
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for g in var.groups : g.key])) == length(var.groups)
    error_message = "groups[*].key values must be unique."
  }

  validation {
    condition     = length(distinct([for g in var.groups : g.email])) == length(var.groups)
    error_message = "groups[*].email values must be unique."
  }

  validation {
    condition = alltrue([
      for g in var.groups : contains(["EMPTY", "WITH_INITIAL_OWNER", "INITIAL_GROUP_CONFIG_UNSPECIFIED"], g.initial_group_config)
    ])
    error_message = "groups[*].initial_group_config must be EMPTY, WITH_INITIAL_OWNER, or INITIAL_GROUP_CONFIG_UNSPECIFIED."
  }

  validation {
    condition = alltrue([
      for g in var.groups : length(g.labels) > 0
    ])
    error_message = "groups[*].labels must contain at least one entry (group type label required by the Cloud Identity API)."
  }

  validation {
    condition = alltrue([
      for g in var.groups : alltrue([
        for m in g.members : length(m.roles) > 0
      ])
    ])
    error_message = "groups[*].members[*].roles must contain at least one role (e.g. [\"MEMBER\"])."
  }

  validation {
    condition = alltrue([
      for g in var.groups : alltrue([
        for m in g.members : alltrue([
          for r in m.roles : contains(["MEMBER", "MANAGER", "OWNER"], r)
        ])
      ])
    ])
    error_message = "groups[*].members[*].roles values must be MEMBER, MANAGER, or OWNER."
  }
}
