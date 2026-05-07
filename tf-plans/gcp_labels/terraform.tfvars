project_id = "main-project-492903"
region     = "us-central1"

tags = {
  env     = "production"
  owner   = "platform-team"
  project = "main-project-492903"
}

# ===========================================================================
# Label profiles
# Each entry produces a merged label map consumed by other Terraform modules.
# ===========================================================================
label_sets = [
  # ── Platform infrastructure — shared services team ────────────────────────
  {
    key         = "platform"
    create      = true
    environment = "production"
    team        = "platform"
    application = "shared-infra"
    cost_center = "cc-1001"
    # No data-classification: platform resources are internal by default.
  },

  # ── Payments API — PCI-scoped, confidential data ──────────────────────────
  {
    key                 = "payments"
    create              = true
    environment         = "production"
    team                = "payments"
    application         = "payments-api"
    cost_center         = "cc-2001"
    data_classification = "confidential"
    extra_labels = {
      compliance = "pci-dss"
    }
  },

  # ── Data engineering pipeline — analytics workloads ──────────────────────
  {
    key         = "data-eng"
    create      = true
    environment = "staging"
    team        = "data-eng"
    application = "analytics-pipeline"
    cost_center = "cc-3001"
    extra_labels = {
      pipeline-version = "v3"
      data-source      = "clickstream"
    }
  },

  # ── Security tooling — audit and compliance resources ─────────────────────
  {
    key                 = "security"
    create              = true
    environment         = "production"
    team                = "security"
    application         = "audit-tooling"
    cost_center         = "cc-4001"
    data_classification = "restricted"
  }
]
