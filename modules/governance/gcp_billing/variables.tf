variable "billing_account_id" {
  description = "The billing account ID in the format XXXXXX-XXXXXX-XXXXXX."
  type        = string
}

variable "project_id" {
  description = "GCP project ID used for provider context only (not linked automatically)."
  type        = string
}

variable "region" {
  description = "Default GCP region used for provider context."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Additional key-value labels merged into common_labels (e.g. owner, team)."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Project → Billing Account linkages
# ---------------------------------------------------------------------------
variable "project_links" {
  description = <<-EOT
    List of projects to link to the billing account.

    Required fields:
      project_id – GCP project ID to attach (e.g. "my-project-123").

    Optional fields:
      create – Set false to skip this entry without removing it from state (default true).
  EOT
  type = list(object({
    project_id = string
    create     = optional(bool, true)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Billing budgets
# ---------------------------------------------------------------------------
variable "budgets" {
  description = <<-EOT
    List of billing budgets to create on the billing account.

    Required fields:
      key          – Unique identifier for Terraform state key.
      display_name – Human-readable name shown in the Cloud Console.

    Optional fields:
      create                        – Skip creation when false (default true).
      budget_amount                 – Spend threshold in the given currency.
                                      Set to 0 to use last_period_amount (previous period spend).
      currency_code                 – ISO 4217 currency code (default "USD").
      projects                      – List of project IDs to filter (empty = all projects).
      services                      – List of GCP service IDs to filter (empty = all services).
      credit_types_treatment        – How credits affect budget: INCLUDE_ALL_CREDITS (default),
                                      EXCLUDE_ALL_CREDITS, or INCLUDE_SPECIFIED_CREDITS.
      label_filters                 – map(string) of ONE resource label key→value filter.
      threshold_percents            – List of integer percentages at which to alert (default [50,90,100]).
      spend_basis                   – CURRENT_SPEND (actual) or FORECASTED_SPEND (default CURRENT_SPEND).
      pubsub_topic                  – Full Pub/Sub topic resource path for programmatic responses.
      notification_channels         – List of Cloud Monitoring notification channel resource names.
      disable_default_iam_recipients – Suppress email to billing admins/users (default false).
  EOT
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

  validation {
    condition = alltrue([
      for b in var.budgets : contains(
        ["INCLUDE_ALL_CREDITS", "EXCLUDE_ALL_CREDITS", "INCLUDE_SPECIFIED_CREDITS"],
        b.credit_types_treatment
      )
    ])
    error_message = "credit_types_treatment must be INCLUDE_ALL_CREDITS, EXCLUDE_ALL_CREDITS, or INCLUDE_SPECIFIED_CREDITS."
  }

  validation {
    condition = alltrue([
      for b in var.budgets : contains(["CURRENT_SPEND", "FORECASTED_SPEND"], b.spend_basis)
    ])
    error_message = "spend_basis must be CURRENT_SPEND or FORECASTED_SPEND."
  }
}

# ---------------------------------------------------------------------------
# Billing account IAM bindings
# ---------------------------------------------------------------------------
variable "iam_bindings" {
  description = <<-EOT
    List of additive IAM bindings on the billing account itself.

    Required fields:
      role   – IAM role (e.g. "roles/billing.viewer").
      member – IAM member (e.g. "user:admin@example.com", "serviceAccount:sa@proj.iam.gserviceaccount.com").
  EOT
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}
