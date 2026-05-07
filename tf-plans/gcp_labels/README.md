# GCP Labels — Deployment Plan

Deployment plan that invokes the [GCP Labels module](../../modules/governance/gcp_labels/README.md) to define and track standardised label profiles for use across all GCP resources.

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Quick Start

```bash
cd tf-plans/gcp_labels

# Initialise providers and module source.
terraform init

# Review the computed label maps.
terraform plan

# Create the label-set state sentinels.
terraform apply
```

---

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Module invocation — passes label_sets and tags to the root module. |
| `variables.tf` | Input variable declarations mirroring the module interface. |
| `locals.tf` | Computes `created_date` and `extra_tags` forwarded to the module. |
| `providers.tf` | Terraform and Google provider version constraints. |
| `outputs.tf` | Pass-through of `label_sets`, `all_label_sets`, and `common_labels`. |
| `terraform.tfvars` | Example values — 4 profiles: platform, payments, data-eng, security. |

---

## Label profiles in `terraform.tfvars`

| Profile key | Team | Environment | Cost Center | Data Classification |
|-------------|------|-------------|-------------|---------------------|
| `platform` | platform | production | cc-1001 | *(none)* |
| `payments` | payments | production | cc-2001 | confidential |
| `data-eng` | data-eng | staging | cc-3001 | *(none)* |
| `security` | security | production | cc-4001 | restricted |

---

## Consuming label outputs in other plans

```hcl
# Reference the labels plan outputs via terraform_remote_state,
# or simply inline the module in the consuming plan.

data "terraform_remote_state" "labels" {
  backend = "gcs"
  config = {
    bucket = "my-tf-state"
    prefix = "gcp_labels"
  }
}

resource "google_storage_bucket" "assets" {
  name     = "my-assets-bucket"
  location = "US"
  labels   = data.terraform_remote_state.labels.outputs.label_sets["platform"]
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `label_sets` | `map(map(string))` — computed label map per active profile key. |
| `all_label_sets` | `map(map(string))` — computed label map for all profiles including `create=false`. |
| `common_labels` | `map(string)` — base labels: `managed-by`, `created-date`, and `var.tags`. |

---

## Related Docs

- [GCP Labels Module](../../modules/governance/gcp_labels/README.md)
- [Labels Explainer](../../modules/governance/gcp_labels/gcp-labels.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
