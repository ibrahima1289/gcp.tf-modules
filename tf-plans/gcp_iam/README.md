# GCP IAM Deployment Plan

Terraform deployment wrapper for the [GCP IAM module](../../modules/security/gcp_iam/README.md). Manages service accounts, custom IAM roles, authoritative IAM bindings, and additive IAM member bindings across project, folder, and organization scopes.

> Back to [Repository Root](../../README.md) · [Module README](../../modules/security/gcp_iam/README.md) · [Service Explainer](../../modules/security/gcp_iam/gcp-iam.md)

---

## Directory Structure

```text
tf-plans/gcp_iam/
├── main.tf           # Module call
├── variables.tf      # Input variable declarations
├── locals.tf         # created_date local
├── outputs.tf        # Pass-through outputs from module
├── providers.tf      # Provider version constraints + optional GCS backend
├── terraform.tfvars  # Variable values (edit before applying)
└── README.md         # This file
```

---

## Required Inputs

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default project ID for service accounts and custom roles. |

## Optional Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Labels merged with `managed_by` and `created_date`. |
| `service_accounts` | `list(object)` | `[]` | Service accounts to create. |
| `custom_roles` | `list(object)` | `[]` | Custom IAM roles at project or org scope. |
| `bindings` | `list(object)` | `[]` | Authoritative IAM bindings (replaces all members for the role). |
| `members` | `list(object)` | `[]` | Additive IAM member bindings (safe for shared roles). |

---

## Outputs

| Output | Description |
|--------|-------------|
| `service_account_ids` | Map of SA key → unique ID. |
| `service_account_emails` | Map of SA key → email address. |
| `service_account_names` | Map of SA key → fully qualified name. |
| `project_custom_role_ids` | Map of role key → project-scoped role ID. |
| `org_custom_role_ids` | Map of role key → org-scoped role ID. |
| `project_binding_etags` | Map of binding key → etag for project bindings. |
| `folder_binding_etags` | Map of binding key → etag for folder bindings. |
| `org_binding_etags` | Map of binding key → etag for org bindings. |
| `project_member_etags` | Map of member key → etag for project member bindings. |
| `folder_member_etags` | Map of member key → etag for folder member bindings. |
| `org_member_etags` | Map of member key → etag for org member bindings. |
| `common_tags` | Merged labels including `managed_by` and `created_date`. |

---

## Quick Start

### 1. Configure `terraform.tfvars`

```hcl
project_id = "my-project-id"

tags = {
  environment = "production"
  team        = "platform"
}

service_accounts = [
  {
    key          = "app-sa"
    account_id   = "my-app-sa"
    display_name = "My Application Service Account"
  }
]

members = [
  {
    key      = "app-sa-storage"
    scope    = "project"
    resource = "my-project-id"
    role     = "roles/storage.objectViewer"
    member   = "serviceAccount:my-app-sa@my-project-id.iam.gserviceaccount.com"
  }
]
```

### 2. Initialize and apply

```bash
# Authenticate
gcloud auth application-default login --no-launch-browser

# Navigate to the plan directory
cd tf-plans/gcp_iam

# Initialize Terraform and download providers
terraform init

# Validate syntax and variable values
terraform validate

# Preview changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### 3. Inspect outputs

```bash
# View all outputs
terraform output

# View service account emails (useful for constructing member strings)
terraform output -json service_account_emails
```

---

## Example Configurations

### Service account with additive member binding

```hcl
service_accounts = [
  {
    key          = "data-pipeline-sa"
    account_id   = "data-pipeline-sa"
    display_name = "Data Pipeline Service Account"
  }
]

members = [
  {
    key      = "pipeline-bigquery"
    scope    = "project"
    resource = "my-project-id"
    role     = "roles/bigquery.dataEditor"
    member   = "serviceAccount:data-pipeline-sa@my-project-id.iam.gserviceaccount.com"
  }
]
```

### Custom role with authoritative binding

> **Warning:** The binding below is **authoritative** — it will remove any principals currently holding `roles/logging.viewer` on the project that are not listed here.

```hcl
custom_roles = [
  {
    key         = "log-reader"
    role_id     = "customLogReader"
    title       = "Custom Log Reader"
    permissions = ["logging.logEntries.list", "logging.logs.list"]
    scope       = "project"
  }
]

bindings = [
  {
    key      = "log-reader-binding"
    scope    = "project"
    resource = "my-project-id"
    role     = "projects/my-project-id/roles/customLogReader"
    members  = ["group:sre-team@example.com"]
  }
]
```

### Folder-scoped member binding

```hcl
members = [
  {
    key      = "folder-org-viewer"
    scope    = "folder"
    resource = "987654321098"
    role     = "roles/viewer"
    member   = "user:admin@example.com"
  }
]
```

---

## Authoritative vs Additive IAM — Decision Guide

| Scenario | Recommendation |
|----------|----------------|
| Terraform is the **sole** manager of all role members for a specific role on a resource | `bindings` (authoritative) |
| Multiple Terraform configs or manual assignments exist for the same role | `members` (additive) |
| Granting a service account access to a shared role | `members` (additive) |
| Bootstrapping a new project with controlled access | Either; authoritative is safer for greenfield |
| Org-level roles shared across teams | `members` (additive) — modifying org bindings authoritatively is high-risk |

---

## Enabling the GCS Backend

Uncomment the `backend "gcs"` block in `providers.tf` and update with your state bucket:

```hcl
backend "gcs" {
  bucket = "my-terraform-state-bucket"
  prefix = "gcp-iam"
}
```

Re-run `terraform init` after enabling the backend to migrate state.

---

## Related Docs

- [GCP IAM Module](../../modules/security/gcp_iam/README.md)
- [Service Explainer: Google Cloud IAM](../../modules/security/gcp_iam/gcp-iam.md)
- [GCP Organization Module](../../modules/hierarchy/organization/README.md)
- [GCP Project Module](../../modules/hierarchy/project/README.md)
- [Terraform Deployment Guide](../../gcp-terraform-deployment-cli-github-actions.md)
- [Repository Root](../../README.md)
