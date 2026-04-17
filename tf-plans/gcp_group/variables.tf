variable "customer_id" {
  description = "Cloud Identity or Workspace customer ID (e.g. 'C0xxxxxxx'). All groups belong to this tenant."
  type        = string
}

variable "tags" {
  description = "Common governance tags merged with generated metadata and exposed in outputs."
  type        = map(string)
  default     = {}
}

variable "groups" {
  description = "List of Cloud Identity group configurations to create."
  type = list(object({
    key          = string
    email        = string
    display_name = optional(string, "")
    description  = optional(string, "")
    labels       = optional(map(string), { "cloudidentity.googleapis.com/groups.discussion_forum" = "" })

    initial_group_config = optional(string, "EMPTY")
    create               = optional(bool, true)

    members = optional(list(object({
      key          = string
      member_email = string
      roles        = optional(list(string), ["MEMBER"])
      create       = optional(bool, true)
    })), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for g in var.groups : g.key])) == length(var.groups)
    error_message = "groups[*].key values must be unique."
  }
}
