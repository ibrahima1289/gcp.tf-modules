# GCP Cloud Billing — Deployment Plan

Deployment plan that invokes the [GCP Cloud Billing module](../../modules/governance/gcp_billing/README.md) to manage project-to-billing-account linkage, spend budgets with multi-threshold alerting, and additive IAM bindings.

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Quick Start

```bash
cd tf-plans/gcp_billing

# Initialise providers and module source.
terraform init

# Review planned changes — budgets, links, IAM.
terraform plan

# Apply — creates budgets, links projects, and grants IAM.
terraform apply
```

---

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Module invocation — wires billing_account_id, project_links, budgets, and iam_bindings. |
| `variables.tf` | Input variable declarations mirroring the module interface. |
| `locals.tf` | Computes `created_date` and `extra_tags` forwarded to the module. |
| `providers.tf` | Terraform `>= 1.5` and Google provider `>= 6.0` with project + region. |
| `outputs.tf` | Pass-through of all 5 module outputs. |
| `terraform.tfvars` | Example values — 2 project links, 4 budgets, 2 IAM bindings. |

---

## Budget examples in `terraform.tfvars`

| Budget key | Scope | Amount | Thresholds | Notification |
|------------|-------|--------|-----------|--------------|
| `org-monthly` | All projects | $10,000 | 50 / 90 / 100 % | Pub/Sub |
| `app-prod-compute` | app-prod-492903 | $4,000 | 75 / 90 / 100 % (forecast) | Default IAM email |
| `data-prod-anomaly` | data-prod-492903 | Last period | 110 / 130 % | Default IAM email |
| `security-audit` | label team=security | $500 | 80 / 100 % | Default IAM email |

---

## Required permissions

| Role | Scope | Why |
|------|-------|-----|
| `roles/billing.user` | Billing account | Create and update budgets |
| `roles/billing.admin` | Billing account | Manage IAM on the billing account |
| `roles/resourcemanager.projectBillingManager` | Each project | Link project to billing account |

---

## Outputs

| Output | Description |
|--------|-------------|
| `project_billing_links` | `map(string)` — project_id → billing account ID. |
| `budget_ids` | `map(string)` — budget key → resource name. |
| `budget_names` | `map(string)` — budget key → display name. |
| `iam_binding_ids` | `map(string)` — role/member → binding ID. |
| `common_labels` | `map(string)` — base labels: `managed-by`, `created-date`, `var.tags`. |

---

## Related Docs

- [GCP Cloud Billing Module](../../modules/governance/gcp_billing/README.md)
- [Cloud Billing Explainer](../../modules/governance/gcp_billing/gcp-billing.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
