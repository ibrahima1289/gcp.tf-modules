# Google Cloud Resource Manager

[Cloud Resource Manager](https://cloud.google.com/resource-manager/docs) provides the API and tooling to programmatically manage GCP's **organization → folder → project** resource hierarchy. It controls how resources are grouped, how IAM policies are inherited, and how organization-wide policies (via Organization Policy Service) are enforced. Terraform interacts with Resource Manager to create and configure folders, projects, and org-level policies.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Every GCP resource lives within a **project**. Projects are grouped into **folders** (for team or environment boundaries) and folders roll up into an **organization node** rooted at a Google Workspace or Cloud Identity domain.

```text
Organization  (org ID: 123456789)
├── Folder: Shared Services
│   ├── Project: logging-prod
│   └── Project: networking-hub
├── Folder: Business Unit A
│   ├── Folder: Production
│   │   └── Project: app-prod
│   └── Folder: Non-Production
│       ├── Project: app-dev
│       └── Project: app-staging
└── Folder: Business Unit B
    └── Project: analytics-prod
```

| Capability | Description |
|------------|-------------|
| **Organizations** | Root node tied to a Workspace / Cloud Identity domain; single per tenant |
| **Folders** | Grouping containers; up to 10 levels deep; hold other folders or projects |
| **Projects** | Billing and API boundary; all resources belong to exactly one project |
| **IAM inheritance** | Policies set at org/folder flow down; can be overridden at lower levels |
| **Organization Policies** | Constraints that govern what can be configured at any node in the hierarchy |
| **Tags** | Key-value pairs attached to the hierarchy for policy targeting and cost attribution |
| **Liens** | Temporary locks that prevent accidental project deletion |

---

## Core Concepts

### Hierarchy Nodes

| Resource | Terraform Resource | Unique Identifier |
|----------|--------------------|-------------------|
| Organization | *(data source only)* `data.google_organization` | Org ID / domain |
| Folder | `google_folder` | Folder ID |
| Project | `google_project` | Project ID (globally unique string) |

Terraform cannot *create* an organization node — it is provisioned by Google when a domain is enrolled. Folders and projects are fully managed via Terraform.

```hcl
data "google_organization" "org" {
  domain = "example.com"
}

resource "google_folder" "bu_a" {
  display_name = "Business Unit A"
  parent       = data.google_organization.org.name   # "organizations/123456789"
}

resource "google_folder" "bu_a_prod" {
  display_name = "Production"
  parent       = google_folder.bu_a.name             # "folders/987654321"
}

resource "google_project" "app_prod" {
  name            = "App Production"
  project_id      = "app-prod-a1b2c3"
  folder_id       = google_folder.bu_a_prod.folder_id
  billing_account = "ABCDEF-123456-GHIJKL"
}
```

### IAM Policy Inheritance

IAM bindings are **additive** down the hierarchy. A role granted at the folder level is automatically effective in all child projects.

```text
Org  ──► roles/resourcemanager.folderViewer  →  inherited by all folders & projects
Folder ──► roles/editor                       →  inherited by all child projects
Project ──► roles/viewer                      →  applies only to this project
```

> Use **deny policies** (`google_iam_deny_policy`) to block permissions even when granted at a lower level.

### Organization Policies

Org policies apply boolean constraints or list constraints at any hierarchy node. Child nodes inherit unless overridden.

| Common Constraint | Description |
|-------------------|-------------|
| `constraints/compute.requireShieldedVm` | Require Shielded VM on all Compute instances |
| `constraints/compute.vmExternalIpAccess` | Restrict or deny external IP assignment |
| `constraints/iam.allowedPolicyMemberDomains` | Restrict IAM bindings to specific domains (Domain Restricted Sharing) |
| `constraints/gcp.resourceLocations` | Limit resource creation to approved regions |
| `constraints/compute.disableSerialPortAccess` | Block serial port access on VMs |
| `constraints/storage.uniformBucketLevelAccess` | Enforce uniform IAM on all GCS buckets |

```hcl
resource "google_org_policy_policy" "restrict_locations" {
  name   = "${data.google_organization.org.name}/policies/gcp.resourceLocations"
  parent = data.google_organization.org.name

  spec {
    rules {
      values {
        allowed_values = ["in:us-locations", "in:eu-locations"]
      }
    }
  }
}
```

### Resource Tags

Tags (`google_tags_tag_key`, `google_tags_tag_value`, `google_tags_tag_binding`) attach structured metadata to org, folder, or project nodes for policy targeting and cost attribution:

```hcl
resource "google_tags_tag_key" "env" {
  parent      = data.google_organization.org.name
  short_name  = "environment"
  description = "Deployment environment"
}

resource "google_tags_tag_value" "prod" {
  parent      = google_tags_tag_key.env.name
  short_name  = "production"
}

resource "google_tags_tag_binding" "proj_env" {
  name      = "tagBindings/${google_project.app_prod.name}/tagValues/${google_tags_tag_value.prod.name}"
  parent    = "//cloudresourcemanager.googleapis.com/${google_project.app_prod.name}"
  tag_value = google_tags_tag_value.prod.name
}
```

### Project Liens

A **lien** blocks a project from being deleted until the lien is explicitly removed. Use this to protect shared service projects (e.g., logging, networking hub):

```hcl
resource "google_resource_manager_lien" "protect" {
  parent       = "projects/${google_project.logging.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "terraform-protection"
  reason       = "Shared logging project — do not delete without approval"
}
```

---

## Project Lifecycle

```text
CREATE ──► ACTIVE ──► DELETE_REQUESTED (30-day grace period) ──► DELETED
                             ↑
                     Lien prevents this step
```

| State | Description |
|-------|-------------|
| `ACTIVE` | Normal operating state; APIs and billing active |
| `DELETE_REQUESTED` | Scheduled for deletion; resources still accessible for 30 days |
| `DELETED` | Project and all resources permanently purged |

> Re-use of a deleted project ID is not permitted. Include a random suffix (`random_id`) in the `project_id` to avoid conflicts across environments.

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_folder` | Create and manage folders in the hierarchy |
| `google_project` | Create projects, link billing accounts |
| `google_project_service` | Enable/disable GCP APIs on a project |
| `google_folder_iam_binding` | Authoritative IAM binding on a folder |
| `google_folder_iam_member` | Additive IAM member on a folder |
| `google_project_iam_binding` | Authoritative IAM binding on a project |
| `google_project_iam_member` | Additive IAM member on a project |
| `google_org_policy_policy` | Org Policy constraint at any hierarchy node |
| `google_tags_tag_key` | Define a tag key in the org |
| `google_tags_tag_value` | Define a tag value |
| `google_tags_tag_binding` | Attach a tag value to a resource |
| `google_resource_manager_lien` | Place a deletion lock on a project |

---

## Security Guidance

- Apply **Domain Restricted Sharing** (`constraints/iam.allowedPolicyMemberDomains`) at the org level to prevent IAM bindings to external identities.
- Use **resource location constraints** (`constraints/gcp.resourceLocations`) to enforce data residency requirements.
- Enable **VPC Service Controls** at the folder level for projects that handle sensitive data.
- Assign `roles/resourcemanager.projectCreator` only to automation service accounts — not to individual users.
- Protect all shared service projects with a **lien** to prevent accidental deletion.
- Prefer **folder-level IAM** for team-wide roles over repeating bindings on every project.
- Use **tags** (not labels) for org policy targeting — labels are metadata only and cannot gate policies.
- Audit all hierarchy changes via **Cloud Audit Logs** (`cloudresourcemanager.googleapis.com` data access logs).

---

## Related Docs

- [Cloud Resource Manager Overview](https://cloud.google.com/resource-manager/docs/overview)
- [Organization Policy Service](https://cloud.google.com/resource-manager/docs/organization-policy/overview)
- [Resource Hierarchy Best Practices](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations#resource-hierarchy)
- [Tags Overview](https://cloud.google.com/resource-manager/docs/tags/tags-overview)
- [google_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder)
- [google_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project)
- [google_org_policy_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy)
- [google_resource_manager_lien](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/resource_manager_lien)
