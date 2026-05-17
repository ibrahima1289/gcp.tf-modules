# ===========================================================================
# Step 1: Project → Billing Account linkage
# Attaches each project in var.project_links to the billing account.
# Requires roles/billing.user on the billing account and
# roles/resourcemanager.projectBillingManager on the project.
# ===========================================================================
resource "google_billing_project_info" "links" {
  for_each = { for pl in var.project_links : pl.project_id => pl if pl.create }

  project         = each.value.project_id
  billing_account = var.billing_account_id
}

# ===========================================================================
# Step 2: Billing budgets
# One google_billing_budget per active entry in var.budgets.
# Thresholds are advisory — they do not stop resource usage.
# Each budget can notify via email and/or a Pub/Sub topic.
# ===========================================================================
resource "google_billing_budget" "budgets" {
  for_each = { for b in var.budgets : b.key => b if b.create }

  billing_account = var.billing_account_id
  display_name    = each.value.display_name

  # ── Budget scope filter ──────────────────────────────────────────────────
  budget_filter {
    # Restrict to specific projects (empty list = all projects on the account).
    projects = length(each.value.projects) > 0 ? [
      for p in each.value.projects : "projects/${p}"
    ] : []

    # Restrict to specific services (empty list = all services).
    services = length(each.value.services) > 0 ? [
      for s in each.value.services : "services/${s}"
    ] : []

    # Filter by credit types to include (empty = all credits included).
    credit_types_treatment = each.value.credit_types_treatment

    # Optional: map of resource label key→value pairs to filter costs.
    # Pass an empty map to skip label filtering.
    labels = length(each.value.label_filters) > 0 ? each.value.label_filters : {}
  }

  # ── Spend basis ─────────────────────────────────────────────────────────
  # When budget_amount > 0 use a fixed specified_amount; when 0 use
  # last_period_amount so the budget auto-tracks the previous period's spend.
  dynamic "amount" {
    for_each = each.value.budget_amount > 0 ? [1] : []
    content {
      specified_amount {
        currency_code = each.value.currency_code
        units         = tostring(floor(each.value.budget_amount))
        # Nanos represent fractional currency units (e.g. 0.50 USD → 500000000 nanos).
        nanos = floor((each.value.budget_amount - floor(each.value.budget_amount)) * 1e9)
      }
    }
  }

  dynamic "amount" {
    for_each = each.value.budget_amount == 0 ? [1] : []
    content {
      # last_period_amount tracks the previous calendar period's actual spend.
      last_period_amount = true
    }
  }

  # ── Alert thresholds ─────────────────────────────────────────────────────
  # Each threshold_rule fires when spend reaches the given fraction of the budget.
  dynamic "threshold_rules" {
    for_each = each.value.threshold_percents
    content {
      threshold_percent = threshold_rules.value / 100
      spend_basis       = each.value.spend_basis
    }
  }

  # ── Notification channels ────────────────────────────────────────────────
  all_updates_rule {
    # Email notification to billing account administrators and users.
    disable_default_iam_recipients = each.value.disable_default_iam_recipients

    # Optional Pub/Sub topic for programmatic responses (e.g. disable billing).
    pubsub_topic = trimspace(each.value.pubsub_topic) != "" ? each.value.pubsub_topic : null

    # Explicit monitoring notification channel emails.
    monitoring_notification_channels = length(each.value.notification_channels) > 0 ? each.value.notification_channels : []
  }
}

# ===========================================================================
# Step 3: Billing account IAM bindings
# Flat list of role → member bindings on the billing account itself.
# Use additive bindings (iam_member) to avoid overwriting existing grants.
# ===========================================================================
resource "google_billing_account_iam_member" "bindings" {
  for_each = {
    for b in var.iam_bindings : "${b.role}/${b.member}" => b
  }

  billing_account_id = var.billing_account_id
  role               = each.value.role
  member             = each.value.member
}
