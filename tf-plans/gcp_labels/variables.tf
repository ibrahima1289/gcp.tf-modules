variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Base key-value pairs merged into every label map (e.g. owner, project)."
  type        = map(string)
  default     = {}
}

variable "label_sets" {
  description = "List of label profiles. Each entry produces a computed label map for use on GCP resources."
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
