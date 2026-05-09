billing_account_id = "ABCDEF-123456-GHIJKL"
project_id         = "main-project-492903"
region             = "us-central1"

tags = {
  env   = "production"
  owner = "finops-team"
  team  = "platform"
}

# ===========================================================================
# Project → Billing Account links
# ===========================================================================
project_links = [
  # Application production project.
  {
    project_id = "app-prod-492903"
    create     = false
  },
  # Data engineering project.
  {
    project_id = "data-prod-492903"
    create     = false
  }
]

# ===========================================================================
# Billing budgets
# ===========================================================================
budgets = [
  # ── Org-wide monthly cap ─────────────────────────────────────────────────
  # Alerts billing admins at 50%, 90%, and 100% of $10,000.
  {
    key                = "org-monthly"
    display_name       = "Org-Wide Monthly Budget"
    budget_amount      = 10000
    threshold_percents = [50, 90, 100]
    # Notify via Pub/Sub for automated cost-control response.
    pubsub_topic = "projects/main-project-492903/topics/billing-alerts"
  },

  # ── App Prod — Compute & GKE focused ─────────────────────────────────────
  # Scoped to the app-prod project; excludes sustained-use credits for clarity.
  {
    key                    = "app-prod-compute"
    display_name           = "App Prod — Compute + GKE"
    budget_amount          = 4000
    projects               = ["app-prod-492903"]
    services               = ["6F81-5844-456A", "95FF-2EF5-5EA1"] # Compute Engine, GKE
    credit_types_treatment = "EXCLUDE_ALL_CREDITS"
    threshold_percents     = [75, 90, 100]
    spend_basis            = "FORECASTED_SPEND"
  },

  # ── Data Prod — auto-track last period spend ──────────────────────────────
  # budget_amount = 0 means: use last calendar period's actual spend as budget.
  # Useful for anomaly detection without a fixed monthly threshold.
  {
    key                = "data-prod-anomaly"
    display_name       = "Data Prod — Anomaly Detection (Last Period)"
    budget_amount      = 0 # last_period_amount
    projects           = ["data-prod-492903"]
    threshold_percents = [110, 130] # Alert when 10% or 30% over last period.
  },

  # ── Security & Audit tooling — low threshold ─────────────────────────────
  {
    key                = "security-audit"
    display_name       = "Security & Audit Tooling"
    budget_amount      = 500
    label_filters      = { team = "security" }
    threshold_percents = [80, 100]
  }
]

# ===========================================================================
# Billing account IAM
# ===========================================================================
iam_bindings = [
  # FinOps team gets read-only access to billing account.
  {
    role   = "roles/billing.viewer"
    member = "group:finops@example.com"
  },
  # Finance controller needs cost management access.
  {
    role   = "roles/billing.costsManager"
    member = "user:finance-controller@example.com"
  }
]
