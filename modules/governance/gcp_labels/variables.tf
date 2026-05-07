variable "project_id" {
  description = "GCP project ID where label sets are tracked."
  type        = string
}

variable "region" {
  description = "Default GCP region used for provider context."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Additional key-value pairs merged into every computed label map (e.g. owner, project)."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Label-set definitions
# ---------------------------------------------------------------------------
variable "label_sets" {
  description = <<-EOT
    List of label profiles. Each profile produces a merged label map suitable
    for applying to any GCP resource via its `labels` argument.

    Required fields:
      key            – Unique identifier for this label profile (used in Terraform state key).
      environment    – Deployment environment (e.g. production, staging, development).
      team           – Owning team slug (e.g. platform, data-eng, security).
      application    – Application or workload name (e.g. payments-api, data-pipeline).
      cost_center    – Finance cost-center code (e.g. cc-1234).

    Optional fields:
      create              – Set false to skip state tracking for this entry (default true).
      data_classification – Data sensitivity level: public, internal, confidential, restricted.
                            Omit or leave "" to exclude from the label map.
      extra_labels        – Arbitrary additional labels merged last (highest precedence).
  EOT
  type = list(object({
    key                 = string
    create              = optional(bool, true)
    environment         = string
    team                = string
    application         = string
    cost_center         = string
    data_classification = optional(string, "")
    extra_labels        = optional(map(string), {})
  }))
  default = []

  validation {
    condition     = length([for ls in var.label_sets : ls.key]) == length(toset([for ls in var.label_sets : ls.key]))
    error_message = "Each label_set key must be unique."
  }
}
