# GCP Folder — Terraform Deployment Plan

This deployment plan (`tf-plans/gcp_folder`) is a ready-to-use wrapper that calls the reusable [Folder module](../../modules/hierarchy/folder/README.md) to create and manage one or many Google Cloud folders.

---

## Architecture

```text
tf-plans/gcp_folder
        │
        └─► modules/hierarchy/folder
                    │
                    ├─ google_folder (for_each)
                    ├─ google_folder_iam_member (additive)
                    ├─ google_org_policy_policy (folder parent)
                    ├─ google_logging_folder_sink
                    └─ google_essential_contacts_contact
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.5 |
| Google Provider | >= 6.0 |
| Caller permissions | Folder Admin / Organization Admin as needed |
| Authentication | Application Default Credentials or Workload Identity Federation |
| Parent hierarchy | `organizations/<id>` or `folders/<id>` parent path |

---

## Quick Start

```bash
# 1) Authenticate
gcloud auth application-default login

# 2) Initialize
terraform init

# 3) Validate
terraform validate

# 4) Plan
terraform plan -var-file="terraform.tfvars"

# 5) Apply
terraform apply -var-file="terraform.tfvars"
```

---

## Files

| File | Purpose |
|---|---|
| `main.tf` | Calls the folder module with all variables |
| `locals.tf` | Generates `created_date` metadata |
| `variables.tf` | Wrapper input variables |
| `outputs.tf` | Pass-through outputs from module |
| `providers.tf` | Terraform and provider constraints |
| `terraform.tfvars` | Example values for folder deployment |

---

## Variables

### Required

| Variable | Type | Description |
|---|---|---|
| `folders` | `list(object)` | List of folders to create (`key`, `display_name`, optional `parent` or `parent_folder_key`) |
| `default_parent` or folder parent | `string` | Parent path (`organizations/<id>` or `folders/<id>`) supplied globally or per folder |

### Optional

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-central1` | Provider region |
| `labels` | `map(string)` | `{}` | Common tags/labels merged with metadata |
| `folder_iam_members` | `list(object)` | `[]` | Additive folder IAM grants |
| `folder_policies` | `list(object)` | `[]` | Folder OrgPolicy v2 constraints |
| `folder_log_sinks` | `list(object)` | `[]` | Folder logging sinks |
| `folder_essential_contacts` | `list(object)` | `[]` | Folder notification contacts |

> Nested folders are supported with `parent_folder_key` when they reference a top-level folder in the same wrapper; apply deeper folder chains in separate runs/modules.

---

## Outputs

| Output | Description |
|---|---|
| `folder_resource_names` | Folder key to `folders/<id>` map |
| `folder_ids` | Folder key to numeric ID map |
| `folder_display_names` | Folder key to display name map |
| `folder_iam_member_ids` | IAM entry key to resource ID map |
| `folder_policy_names` | Policy key to resource name map |
| `folder_log_sink_names` | Sink key to name map |
| `folder_log_sink_writer_identities` | Sink key to writer identity map |
| `folder_essential_contact_ids` | Contact key to resource ID map |
| `common_labels` | Common metadata labels map |

---

## Related Docs

- [Folder Module README](../../modules/hierarchy/folder/README.md)
- [Organization Module README](../../modules/hierarchy/organization/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Terraform Deployment Guide (CLI & GitHub Actions)](../../gcp-terraform-deployment-cli-github-actions.md)
