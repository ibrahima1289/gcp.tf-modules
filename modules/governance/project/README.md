# GCP Project Terraform Module

Manages one or many [Google Cloud Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with optional billing linkage, API enablement, and labels.

This module supports two usage patterns:

1. **Single primary project + optional `additional_projects`**
2. **Wrapper-driven scale-out** (for example [tf-plans/gcp_project](../../../tf-plans/gcp_project/README.md))

---

## Architecture

```text
Inputs (project_id/name + optional additional_projects)
                    |
                    v
           +-----------------------+
           | locals.projects_map   |
           +-----------+-----------+
                       |
       +---------------+----------------+
       |                                |
       v                                v
+---------------------------+  +---------------------------+
| google_project.protected  |  | google_project.standard   |
| lifecycle.prevent_destroy |  | no deletion protection    |
+-------------+-------------+  +-------------+-------------+
              \                          /
               \                        /
                v                      v
           +-------------------------------+
           | locals.created_project_ids    |
           +---------------+---------------+
                           |
                           v
               +-------------------------+
               | google_project_service  |
               | API/service enablement  |
               +-------------------------+
```

---

## Requirements

| Requirement | Version / Note |
|---|---|
| Terraform | `>= 1.5` |
| Provider | `hashicorp/google >= 6.0` |
| Auth | Application Default Credentials (ADC) or Workload Identity Federation |
| Parent scope | Exactly one of `org_id` or `folder_id` per project |

---

## Resources Managed

| Resource | Purpose |
|---|---|
| `google_project.protected` | Create projects with static `prevent_destroy = true` |
| `google_project.standard` | Create projects without deletion protection |
| `google_project_service` | Enable project APIs/services from `enable_services` |

---

## Required Variables

| Name | Type | Description |
|---|---|---|
| `project_id` | `string` | Primary project ID (6–30 chars, lowercase letters/digits/hyphen). |
| `name` | `string` | Primary project display name. |
| `org_id` or `folder_id` | `string` | Exactly one parent must be set for the primary project. |

---

## Optional Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-central1` | Provider region passed from caller. |
| `billing_account` | `string` | `""` | Billing account ID for primary project. |
| `enable_services` | `list(string)` | `[]` | APIs/services to enable for primary project. |
| `labels` | `map(string)` | `{}` | Labels for primary project. |
| `prevent_destroy` | `bool` | `true` | Deletion protection default for primary and additional projects. |
| `additional_projects` | `list(object)` | `[]` | Extra project definitions created in the same module call. |

### `additional_projects` object fields

| Field | Required | Description |
|---|---|---|
| `project_id` | Yes | Unique project ID |
| `name` | Yes | Project display name |
| `billing_account` | No | Billing account ID |
| `org_id` | Conditional | Parent organization ID (mutually exclusive with `folder_id`) |
| `folder_id` | Conditional | Parent folder ID (mutually exclusive with `org_id`) |
| `enable_services` | No | APIs to enable |
| `labels` | No | Per-project labels |
| `prevent_destroy` | No | Per-project override for deletion protection |

---

## Outputs

| Name | Description |
|---|---|
| `project_id` | Primary project ID |
| `project_number` | Primary project number |
| `project_ids` | Map of all project IDs keyed by `project_id` |
| `project_numbers` | Map of all project numbers keyed by `project_id` |

---

## Usage

```hcl
module "project" {
  source = "../../modules/hierarchy/project"

  # Primary project
  project_id      = "example-proj-dev1"
  name            = "Example Project Dev"
  billing_account = "000000-000000-000000"
  org_id          = "123456789012"
  enable_services = [
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]
  labels = {
    environment = "dev"
    owner       = "platform-team"
  }

  # Optional additional projects
  additional_projects = [
    {
      project_id      = "example-proj-prod1"
      name            = "Example Project Prod"
      billing_account = "000000-000000-000000"
      folder_id       = "987654321098"
      enable_services = [
        "compute.googleapis.com",
        "container.googleapis.com"
      ]
      labels = {
        environment = "prod"
      }
      prevent_destroy = true
    }
  ]
}
```

---

## Validation & Behavior

- Enforces valid `project_id` format for primary and additional projects.
- Enforces uniqueness for `additional_projects.project_id`.
- Enforces exactly one parent (`org_id` or `folder_id`) per project.
- Uses static lifecycle configuration by splitting protected vs standard resources (required by Terraform lifecycle constraints).
- Avoids module-local provider configuration so callers can safely use `for_each` on this module.

---

## Related Docs

- [What is a Google Cloud Project?](gcp-project.md)
- [GCP Organization Module](../organization/README.md)
- [GCP Folder Module](../folder/README.md)
- [GCP Project Deployment Plan](../../../tf-plans/gcp_project/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
