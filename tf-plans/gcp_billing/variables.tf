variable "billing_account_id" {
  description = "The billing account ID in the format XXXXXX-XXXXXX-XXXXXX."
  type        = string
}

variable "project_id" {
  description = "GCP project ID for provider context."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Extra key-value labels merged into common_labels (e.g. owner, team)."
  type        = map(string)
  default     = {}
}

variable "project_links" {
  description = "Projects to link to the billing account."
  type = list(object({
    project_id = string
    create     = optional(bool, true)
  }))
  default = []
}

variable "budgets" {
  description = "List of billing budgets to create."
  type = list(object({
    key                            = string
    create                         = optional(bool, true)
    display_name                   = string
    budget_amount                  = optional(number, 0)
    currency_code                  = optional(string, "USD")
    projects                       = optional(list(string), [])
    services                       = optional(list(string), [])
    credit_types_treatment         = optional(string, "INCLUDE_ALL_CREDITS")
    label_filters                  = optional(map(string), {})
    threshold_percents             = optional(list(number), [50, 90, 100])
    spend_basis                    = optional(string, "CURRENT_SPEND")
    pubsub_topic                   = optional(string, "")
    notification_channels          = optional(list(string), [])
    disable_default_iam_recipients = optional(bool, false)
  }))
  default = []

  validation {
    condition     = length([for b in var.budgets : b.key]) == length(toset([for b in var.budgets : b.key]))
    error_message = "Each budget key must be unique."
  }
}

variable "iam_bindings" {
  description = "Additive IAM bindings on the billing account."
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}
