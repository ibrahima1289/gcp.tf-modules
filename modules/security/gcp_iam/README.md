# GCP IAM Module

Terraform module for managing Google Cloud Identity and Access Management (IAM) resources at project, folder, and organization scope. Supports service account creation, custom role creation, authoritative IAM bindings, and additive IAM member bindings.

> Back to [Repository Root](../../README.md) · [Service Explainer](gcp-iam.md)

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                         gcp_iam module                                  │
│                                                                         │
│  var.service_accounts ──► google_service_account                        │
│                                  │                                      │
│  var.custom_roles ─┬──► google_project_iam_custom_role (scope=project)  │
│                    └──► google_organization_iam_custom_role (scope=org) │
│                                                                         │
│  var.bindings ─────┬──► google_project_iam_binding  (scope=project)     │
│   (authoritative)  ├──► google_folder_iam_binding   (scope=folder)      │
│                    └──► google_organization_iam_binding (scope=org)     │
│                                                                         │
│  var.members ──────┬──► google_project_iam_member   (scope=project)     │
│   (additive)       ├──► google_folder_iam_member    (scope=folder)      │
│                    └──► google_organization_iam_member (scope=org)      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Binding vs Member: When to use each

| Approach | Resource | Semantics | Use When |
|----------|----------|-----------|----------|
| **Authoritative binding** | `google_*_iam_binding` | Replaces **all** members for the specified role on the target resource. Non-listed members are removed. | You fully own the role assignment for that resource and want Terraform to be the sole source of truth. |
| **Additive member** | `google_*_iam_member` | Adds a **single** member without affecting other members for that role. | Multiple configurations share a role on a resource, or you cannot enumerate all existing members in Terraform. |

---

## Resources Created

| Resource | Description | For Each Key |
|----------|-------------|--------------|
| `google_service_account` | Creates a service account | `service_accounts[*].key` |
| `google_project_iam_custom_role` | Custom role at project scope | `custom_roles[*].key` where `scope = "project"` |
| `google_organization_iam_custom_role` | Custom role at org scope | `custom_roles[*].key` where `scope = "organization"` |
| `google_project_iam_binding` | Authoritative binding at project scope | `bindings[*].key` where `scope = "project"` |
| `google_folder_iam_binding` | Authoritative binding at folder scope | `bindings[*].key` where `scope = "folder"` |
| `google_organization_iam_binding` | Authoritative binding at org scope | `bindings[*].key` where `scope = "organization"` |
| `google_project_iam_member` | Additive member binding at project scope | `members[*].key` where `scope = "project"` |
| `google_folder_iam_member` | Additive member binding at folder scope | `members[*].key` where `scope = "folder"` |
| `google_organization_iam_member` | Additive member binding at org scope | `members[*].key` where `scope = "organization"` |

---

## Usage

### Minimal — create a service account

```hcl
module "iam" {
  source = "../../modules/security/gcp_iam"

  project_id = "my-project-id"

  service_accounts = [
    {
      key          = "app-sa"
      account_id   = "my-app-sa"
      display_name = "My Application Service Account"
    }
  ]
}
```

### Full — service accounts, custom role, bindings, and members

```hcl
module "iam" {
  source = "../../modules/security/gcp_iam"

  project_id = "my-project-id"

  tags = {
    environment = "production"
    team        = "platform"
  }

  service_accounts = [
    {
      key          = "pipeline-sa"
      account_id   = "data-pipeline-sa"
      display_name = "Data Pipeline Service Account"
      description  = "Service account for the nightly data pipeline"
    },
    {
      key        = "readonly-sa"
      account_id = "readonly-sa"
      disabled   = false
    }
  ]

  custom_roles = [
    {
      key         = "bucket-reader"
      role_id     = "customBucketReader"
      title       = "Custom Bucket Reader"
      description = "Read-only access to specific storage buckets"
      permissions = [
        "storage.buckets.get",
        "storage.objects.get",
        "storage.objects.list"
      ]
      scope = "project"
    }
  ]

  # Authoritative: Terraform owns all members for this role on this project.
  bindings = [
    {
      key      = "viewer-binding"
      scope    = "project"
      resource = "my-project-id"
      role     = "roles/viewer"
      members  = [
        "serviceAccount:readonly-sa@my-project-id.iam.gserviceaccount.com",
        "group:developers@example.com"
      ]
    }
  ]

  # Additive: adds members without disturbing any others for the role.
  members = [
    {
      key      = "pipeline-sa-storage"
      scope    = "project"
      resource = "my-project-id"
      role     = "roles/storage.objectAdmin"
      member   = "serviceAccount:data-pipeline-sa@my-project-id.iam.gserviceaccount.com"
    },
    {
      key      = "folder-viewer"
      scope    = "folder"
      resource = "123456789012"
      role     = "roles/viewer"
      member   = "user:admin@example.com"
    }
  ]
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `project_id` | `string` | — | ✅ | Default project ID used when no per-resource project is specified. |
| `tags` | `map(string)` | `{}` | | Resource labels merged with module defaults. |
| `service_accounts` | `list(object)` | `[]` | | List of service accounts to create. |
| `custom_roles` | `list(object)` | `[]` | | List of custom IAM roles to create. |
| `bindings` | `list(object)` | `[]` | | List of authoritative IAM bindings (replaces all members for the role). |
| `members` | `list(object)` | `[]` | | List of additive IAM member bindings. |

### `service_accounts` object attributes

| Attribute | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `key` | `string` | — | ✅ | Unique stable key for `for_each`. |
| `account_id` | `string` | — | ✅ | Account ID suffix (6-30 chars, lowercase). |
| `display_name` | `string` | `""` | | Human-readable display name. |
| `description` | `string` | `""` | | Human-readable description. |
| `project_id` | `string` | `""` | | Override project. Defaults to `var.project_id`. |
| `disabled` | `bool` | `false` | | Whether to disable the service account. |
| `create` | `bool` | `true` | | Set to `false` to skip resource creation while keeping the entry in config. |

### `custom_roles` object attributes

| Attribute | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `key` | `string` | — | ✅ | Unique stable key for `for_each`. |
| `role_id` | `string` | — | ✅ | Role ID (alphanumeric + underscores, max 64 chars). |
| `title` | `string` | — | ✅ | Human-readable title. |
| `description` | `string` | `""` | | Role description. |
| `permissions` | `list(string)` | — | ✅ | IAM permissions to grant. |
| `scope` | `string` | `"project"` | | `"project"` or `"organization"`. |
| `resource` | `string` | `""` | | Project ID or Org ID. Defaults to `var.project_id` for project scope. |
| `stage` | `string` | `"GA"` | | `GA`, `BETA`, `ALPHA`, `DEPRECATED`, `DISABLED`, or `EAP`. |
| `create` | `bool` | `true` | | Set to `false` to skip resource creation while keeping the entry in config. |

### `bindings` object attributes

| Attribute | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `key` | `string` | — | ✅ | Unique stable key for `for_each`. |
| `scope` | `string` | — | ✅ | `"project"`, `"folder"`, or `"organization"`. |
| `resource` | `string` | — | ✅ | Project ID, folder numeric ID, or org numeric ID. |
| `role` | `string` | — | ✅ | IAM role (e.g. `"roles/compute.viewer"`). |
| `members` | `list(string)` | — | ✅ | Member list (e.g. `["serviceAccount:sa@proj.iam.gserviceaccount.com"]`). |
| `create` | `bool` | `true` | | Set to `false` to skip resource creation while keeping the entry in config. |

### `members` object attributes

| Attribute | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `key` | `string` | — | ✅ | Unique stable key for `for_each`. |
| `scope` | `string` | — | ✅ | `"project"`, `"folder"`, or `"organization"`. |
| `resource` | `string` | — | ✅ | Project ID, folder numeric ID, or org numeric ID. |
| `role` | `string` | — | ✅ | IAM role to grant. |
| `member` | `string` | — | ✅ | Single member string. |
| `create` | `bool` | `true` | | Set to `false` to skip resource creation while keeping the entry in config. |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `service_account_ids` | `map(string)` | Map of SA key → unique ID. |
| `service_account_emails` | `map(string)` | Map of SA key → email address. |
| `service_account_names` | `map(string)` | Map of SA key → fully qualified name. |
| `project_custom_role_ids` | `map(string)` | Map of role key → project-scoped role ID. |
| `org_custom_role_ids` | `map(string)` | Map of role key → org-scoped role ID. |
| `project_binding_etags` | `map(string)` | Map of binding key → etag for project bindings. |
| `folder_binding_etags` | `map(string)` | Map of binding key → etag for folder bindings. |
| `org_binding_etags` | `map(string)` | Map of binding key → etag for org bindings. |
| `project_member_etags` | `map(string)` | Map of member key → etag for project member bindings. |
| `folder_member_etags` | `map(string)` | Map of member key → etag for folder member bindings. |
| `org_member_etags` | `map(string)` | Map of member key → etag for org member bindings. |
| `common_tags` | `map(string)` | Merged labels including `managed_by` and `created_date`. |

---

## Validations

| Variable | Validation | Error Condition |
|----------|-----------|-----------------|
| `project_id` | Regex `^[a-z][a-z0-9\-]{4,28}[a-z0-9]$` | Invalid project ID format |
| `service_accounts` | Unique `key` values | Duplicate keys cause plan-time failure |
| `service_accounts[*].account_id` | Regex 6-30 chars | Invalid account ID format |
| `custom_roles` | Unique `key` values | Duplicate keys cause plan-time failure |
| `custom_roles[*].scope` | `project` or `organization` | Invalid scope value |
| `custom_roles[*].stage` | Valid stage enum | Invalid stage value |
| `bindings` | Unique `key` values | Duplicate keys cause plan-time failure |
| `bindings[*].scope` | `project`, `folder`, or `organization` | Invalid scope value |
| `members` | Unique `key` values | Duplicate keys cause plan-time failure |
| `members[*].scope` | `project`, `folder`, or `organization` | Invalid scope value |

---

## Important Operational Notes

### Binding authoritative semantics

> `google_*_iam_binding` resources are **authoritative for the specified role**. When applied, they **remove** any members that exist for that role in Google Cloud but are not listed in the `members` attribute. This can silently revoke access.
>
> Always audit existing role memberships before switching to authoritative bindings. Use `members` (additive) when sharing roles across multiple Terraform configurations.

### Folder resource format

The Google provider for `google_folder_iam_binding` and `google_folder_iam_member` requires the `folder` argument in the format `"folders/<numeric_id>"`. This module handles the prefix automatically — supply only the numeric folder ID (e.g. `"123456789012"`) in the `resource` field.

### Service account key rotation

This module creates service accounts but does **not** create or manage service account keys. Key creation and rotation should be handled separately. Prefer Workload Identity Federation over service account keys for compute workloads.

### Custom role naming

Custom role IDs must be unique within the project or organization. Role IDs cannot be reused for 37 days after deletion. Plan role ID naming carefully in environments with frequent role churn.

---

## Related Docs

- [Service Explainer: Google Cloud IAM](gcp-iam.md)
- [GCP IAM Deployment Plan](../../tf-plans/gcp_iam/README.md)
- [GCP Organization Module](../hierarchy/organization/README.md)
- [GCP Folder Module](../hierarchy/folder/README.md)
- [GCP Project Module](../hierarchy/project/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Repository Root](../../README.md)
