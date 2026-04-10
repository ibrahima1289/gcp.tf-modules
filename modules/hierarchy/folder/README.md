# GCP Folder Terraform Module

Manages one or many [Google Cloud Folders](https://cloud.google.com/resource-manager/docs/creating-managing-folders) with optional folder-level IAM members, OrgPolicy v2 constraints, log sinks, and essential contacts.

---

## Architecture

```text
+---------------------------------------------------------------+
| Parent Node                                                   |
| organizations/<id> or folders/<id>                            |
+-------------------------------+-------------------------------+
                                |
                                v
           +-------------------------------+
           | google_folder.top_level       |
           | platform, apps, shared, ...   |
           +---------------+---------------+
                           |
                           v
           +-------------------------------+
           | google_folder.nested          |
           | security under platform, ...  |
           +---------------+---------------+
                                 |
     +---------------------------+------------------------------+
     |                           |                              |
     v                           v                              v
+------------+         +--------------------+         +-------------------+
| IAM Member |         | Org Policy (v2)    |         | Logging Sink      |
| additive   |         | boolean/list rules |         | include_children  |
+------------+         +--------------------+         +-------------------+
                                 |
                                 v
                       +-----------------------+
                       | Essential Contacts    |
                       +-----------------------+
```

---

## Requirements

| Requirement | Version / Note |
|---|---|
| Terraform | `>= 1.5` |
| Provider | `hashicorp/google >= 6.0` |
| Auth | Application Default Credentials (ADC) or Workload Identity Federation |
| Permission scope | Folder Admin / Organization Admin depending on parent path |

---

## Resources Managed

| Resource | Purpose |
|---|---|
| `google_folder.top_level` | Creates top-level folders against explicit/default parent |
| `google_folder.nested` | Creates one-level nested folders referencing top-level keys |
| `google_folder_iam_member` | Additive IAM grants at folder scope |
| `google_org_policy_policy` | Folder-level OrgPolicy v2 constraints |
| `google_logging_folder_sink` | Folder-level logging export |
| `google_essential_contacts_contact` | Folder-level notification contacts |

---

## Required Variables

| Name | Type | Description |
|---|---|---|
| `folders` | `list(object)` | Folders to create. Each item includes `key`, `display_name`, and optional `parent` or `parent_folder_key`. |
| `default_parent` or per-folder parent | `string` | Provide parent at module level (`default_parent`) or per folder (`parent`/`parent_folder_key`). |

---

## Optional Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-central1` | Region for provider config (folder resources are global). |
| `default_parent` | `string` | `""` | Fallback parent (`organizations/<id>` or `folders/<id>`). |
| `folder_iam_members` | `list(object)` | `[]` | Additive folder IAM grants (`key`, `folder_key`, `role`, `member`). |
| `folder_policies` | `list(object)` | `[]` | Folder OrgPolicy v2 settings (`boolean`/`list`). |
| `folder_log_sinks` | `list(object)` | `[]` | Folder log sinks (`name`, `destination`, `filter`, `include_children`). |
| `folder_essential_contacts` | `list(object)` | `[]` | Folder notification contacts. |
| `labels` | `map(string)` | `{}` | Common labels/tags merged with `created_date` and `managed_by`. |

---

## Outputs

| Name | Description |
|---|---|
| `folder_resource_names` | Map of folder key → `folders/<id>`. |
| `folder_ids` | Map of folder key → numeric folder ID. |
| `folder_display_names` | Map of folder key → display name. |
| `folder_iam_member_ids` | Map of IAM entry key → resource ID. |
| `folder_policy_names` | Map of policy key → policy resource name. |
| `folder_log_sink_names` | Map of sink key → sink name. |
| `folder_log_sink_writer_identities` | Map of sink key → sink writer identity. |
| `folder_essential_contact_ids` | Map of contact key → resource ID. |
| `common_labels` | Labels/tags map with `created_date` and `managed_by`. |

---

## Usage

```hcl
module "folder" {
  source = "../../modules/hierarchy/folder"

  # Step 1: provider region.
  region = "us-central1"

  # Step 2: default parent for top-level folders.
  default_parent = "organizations/123456789012"

  # Step 3: create multiple folders (including nested folders).
  folders = [
    {
      key          = "platform"
      display_name = "platform"
    },
    {
      key               = "security"
      display_name      = "security"
      parent_folder_key = "platform"
    }
  ]

  # Step 4: additive IAM grants.
  folder_iam_members = [
    {
      key        = "platform-viewer"
      folder_key = "platform"
      role       = "roles/viewer"
      member     = "group:platform-admins@example.com"
    }
  ]

  # Step 5: folder policy.
  folder_policies = [
    {
      key        = "security-no-serial-port"
      folder_key = "security"
      constraint = "compute.disableSerialPortAccess"
      type       = "boolean"
      enforce    = "TRUE"
    }
  ]

  # Step 6: folder log sink.
  folder_log_sinks = [
    {
      key              = "platform-audit"
      folder_key       = "platform"
      name             = "platform-audit-sink"
      destination      = "storage.googleapis.com/my-folder-audit-logs"
      filter           = "logName:\"cloudaudit.googleapis.com\""
      include_children = true
    }
  ]

  # Step 7: folder contact.
  folder_essential_contacts = [
    {
      key                     = "security-contact"
      folder_key              = "security"
      email                   = "security@example.com"
      language_tag            = "en"
      notification_categories = ["SECURITY", "TECHNICAL"]
    }
  ]

  # Step 8: common labels/tags for metadata.
  labels = {
    environment = "platform"
    owner       = "cloud-team"
  }
}
```

---

## Notes

- Uses additive IAM (`google_folder_iam_member`) for safer applies.
- Avoids `null` input assignments by conditionally creating dynamic policy blocks.
- Supports scaling with `for_each` across all resource types.
- Nested folders can reference a top-level folder in the same module call via `parent_folder_key`; deeper folder chains should be applied in separate runs to avoid Terraform graph cycles.
- Ensure required APIs are enabled and caller has folder admin privileges.

---

## Validation & Behavior

- `folders.key` values must be unique.
- For each folder object, only one of `parent` or `parent_folder_key` may be set.
- Every folder must resolve a parent via `parent`, `parent_folder_key`, or `default_parent`.
- `parent_folder_key` cannot self-reference and must point to a top-level folder.
- Contact categories are validated against supported Essential Contacts values.

---

## Related Docs

- [What is a Google Cloud Folder?](gcp-folder.md)
- [GCP Organization Module](../organization/README.md)
- [GCP Project Module](../project/README.md)
- [GCP Folder Deployment Plan](../../../tf-plans/gcp_folder/README.md)
- [GCP Project Deployment Plan](../../../tf-plans/gcp_project/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
