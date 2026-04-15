# Google Cloud IAM (Identity and Access Management)

Google Cloud IAM is the access control plane for all Google Cloud resources. It defines **who** (identity) can perform **what actions** (permissions) on **which resources** (projects, folders, organizations, and individual services).

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md) · [Module README](README.md)

---

## Overview

IAM in Google Cloud follows a **deny-by-default** model. Access is granted by attaching IAM policies to resource nodes in the hierarchy. Every Google Cloud API call is evaluated against the caller's effective permissions, which are computed as the union of all policies inherited down the resource hierarchy (Organization → Folder → Project → Resource).

IAM addresses four key questions:

| Question | IAM Concept |
|----------|-------------|
| Who is making the request? | **Principal** (user, group, service account, domain, or special group) |
| What can they do? | **Role** (collection of permissions; predefined, basic, or custom) |
| On which resource? | **Resource** (organization, folder, project, bucket, VM, etc.) |
| How is access granted? | **IAM Policy** (binding of principals to roles on a resource) |

---

## Core Concepts

### Principals

A principal is an identity that can be granted access to a resource. Google Cloud recognizes the following principal types:

| Principal Type | Format | Description |
|----------------|--------|-------------|
| Google Account (user) | `user:alice@example.com` | Individual Google account (workspace or consumer) |
| Service Account | `serviceAccount:sa@proj.iam.gserviceaccount.com` | Machine/application identity |
| Google Group | `group:devs@example.com` | Google Group; policies apply to all members |
| Google Workspace domain | `domain:example.com` | All accounts in a Google Workspace domain |
| Cloud Identity domain | `domain:example.com` | Same as Workspace domain but for Cloud Identity tenants |
| `allAuthenticatedUsers` | `allAuthenticatedUsers` | Any authenticated Google identity |
| `allUsers` | `allUsers` | Completely public (anonymous + authenticated) |
| Workforce identity | `principal://iam.googleapis.com/...` | External IdP users via Workforce Identity Federation |
| Workload identity | `principalSet://iam.googleapis.com/...` | External workloads via Workload Identity Federation |

### Roles

Roles bundle permissions together and are the unit of access grant.

| Role Category | Format | Description |
|---------------|--------|-------------|
| **Basic roles** | `roles/owner`, `roles/editor`, `roles/viewer` | Coarse-grained legacy roles; not recommended for production |
| **Predefined roles** | `roles/compute.instanceAdmin.v1` | Curated per-service roles maintained by Google |
| **Custom roles** | `projects/P/roles/R` or `organizations/O/roles/R` | User-defined role combining selected permissions |

> **Best practice:** Prefer predefined roles over basic roles. Use custom roles only when predefined roles are insufficiently scoped.

### IAM Policies and Bindings

An IAM policy is a collection of bindings. Each binding associates a **set of principals** with a **single role** on a resource.

```
Policy (on resource)
  └── Binding
        ├── role:    "roles/storage.objectViewer"
        └── members: ["serviceAccount:sa@proj...", "user:bob@..."]
```

Multiple bindings can exist on the same resource for different roles. A resource can have at most one IAM policy, but that policy contains many bindings.

---

## Resource Hierarchy and Policy Inheritance

IAM policies are inherited down the resource hierarchy. A binding granted at a higher node applies to all child nodes.

```
Organization  (org-level binding applies to ALL resources below)
  └── Folder  (folder-level binding applies to all projects in the folder)
        └── Project  (project-level binding applies to all resources in the project)
              └── Resource  (resource-level binding; most specific scope)
```

**Key inheritance rules:**

- Policies are **additive** — access granted at a higher node cannot be revoked at a lower node.
- `roles/owner` at the folder level grants ownership on all projects in the folder.
- **Deny policies** (IAM Deny, a newer feature) can override inherited allow policies.
- A user with `resourcemanager.projects.setIamPolicy` can only grant roles they already hold.

---

## Service Accounts

Service accounts are identities for workloads (VMs, containers, pipelines) rather than human users.

### Service Account Types

| Type | Description | Use Case |
|------|-------------|----------|
| **User-managed SA** | Created via Terraform or console; managed by the project owner | Application workloads, CI/CD pipelines |
| **Default compute SA** | Auto-created per project at `{project_number}-compute@developer.gserviceaccount.com` | Legacy; not recommended |
| **Google-managed SA** | Created and managed by Google for managed services | Not directly configurable |

### Service Account Best Practices

| Practice | Rationale |
|----------|-----------|
| One SA per workload | Limit blast radius; easier to audit and revoke |
| No SA keys if avoidable | Prefer Workload Identity Federation or attached SA for compute |
| Rotate keys regularly if keys are required | Keys do not expire automatically |
| Grant least-privilege roles | Avoid broad roles like `roles/editor` on service accounts |
| Disable/delete unused SAs | Dormant service accounts are a risk surface |

---

## Custom Roles

When no predefined role provides the exact permissions needed, custom roles allow building precisely scoped roles.

### Custom Role Constraints

| Constraint | Detail |
|------------|--------|
| **Permission availability** | Not all permissions can be used in custom roles (testable via `gcloud iam list-testable-permissions`) |
| **Scope** | Project-scoped or Organization-scoped |
| **ID uniqueness** | Role ID must be unique within the project or org |
| **37-day lock** | Deleted role IDs cannot be reused for 37 days |
| **Max custom roles** | 300 per project, 1000 per org (soft limits) |
| **Stages** | `ALPHA`, `BETA`, `GA`, `DEPRECATED`, `DISABLED`, `EAP` |

---

## IAM Conditions

IAM Conditions allow adding **attribute-based access control** to bindings, further narrowing when a role applies.

| Condition Attribute | Example Use Case |
|--------------------|-----------------|
| `resource.name` | Grant access only to resources with a specific name prefix |
| `request.time` | Restrict access to business hours or a specific date window |
| `resource.type` | Scope a binding to a specific resource type |
| `resource.service` | Limit access to a particular Google Cloud service API |

Conditions are attached directly to binding objects within the IAM policy.

---

## Workload Identity Federation

Workload Identity Federation (WIF) allows external identities (GitHub Actions, AWS IAM, Azure AD, on-premises OIDC/SAML) to impersonate Google service accounts without a service account key.

```
External Identity (e.g. GitHub Actions JWT)
  → Workload Identity Pool
    → OIDC/SAML Provider
      → Mapped to principalSet → service account impersonation
```

**Benefits:**
- No long-lived credentials to manage or rotate
- Short-lived tokens bound to specific workload attributes
- Auditable via Cloud Audit Logs

---

## Audit Logging

All IAM policy changes are recorded in **Cloud Audit Logs** (Admin Activity log). Data Access logs for IAM are optional and must be enabled explicitly.

| Log Type | Captured Events |
|----------|----------------|
| **Admin Activity** | IAM policy changes, role grants, service account creation | Always enabled |
| **Data Access** | `GetIamPolicy`, `TestIamPermissions` calls | Optional (enable per service) |
| **System Event** | Auto-triggered IAM changes by Google | Always enabled |

---

## Security and Operations Guidance

- Enable **org-level audit logging** for IAM Admin Activity across all projects.
- Use **Organization Policy constraints** (`iam.disableServiceAccountKeyCreation`) to block SA key creation where not needed.
- Regularly run **IAM Recommender** to identify and remove excess permissions.
- Use **Workload Identity Federation** instead of service account keys for CI/CD and external workloads.
- Apply **IAM Deny policies** to hard-block specific actions even when allow policies exist.
- Use **VPC Service Controls** in conjunction with IAM to add perimeter-level protection for sensitive services.
- Enforce **Separation of Duties** using Organization Policy and folder-level IAM segregation.
- Avoid `allUsers` and `allAuthenticatedUsers` on any resource containing sensitive data.
- Review and clean up **stale bindings** at the project and folder level on a regular schedule.
- Monitor for unexpected IAM changes using **Cloud Monitoring alerting policies** on audit logs.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_service_account` | Creates a service account | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) |
| `google_project_iam_binding` | Authoritative role binding at project scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam) |
| `google_project_iam_member` | Additive member binding at project scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam) |
| `google_folder_iam_binding` | Authoritative role binding at folder scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_iam) |
| `google_folder_iam_member` | Additive member binding at folder scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_iam) |
| `google_organization_iam_binding` | Authoritative role binding at org scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam) |
| `google_organization_iam_member` | Additive member binding at org scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam) |
| `google_project_iam_custom_role` | Custom IAM role at project scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_custom_role) |
| `google_organization_iam_custom_role` | Custom IAM role at org scope | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam_custom_role) |
| `google_project_iam_policy` | Full replacement of a project IAM policy (**use with caution**) | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam) |
| `google_service_account_iam_binding` | Authoritative binding on a service account resource | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam) |
| `google_service_account_iam_member` | Additive member on a service account resource | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam) |
| `google_service_account_key` | Creates a service account key (prefer WIF instead) | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_key) |
| `google_iam_workload_identity_pool` | Workload Identity Federation pool | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) |
| `google_iam_workload_identity_pool_provider` | OIDC/SAML identity provider in a WIF pool | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) |

---

## Related Docs

- [Module README](README.md)
- [GCP IAM Deployment Plan](../../tf-plans/gcp_iam/README.md)
- [GCP Organization Module](../hierarchy/organization/README.md)
- [GCP Folder Module](../hierarchy/folder/README.md)
- [GCP Project Module](../hierarchy/project/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [Terraform Deployment Guide](../../gcp-terraform-deployment-cli-github-actions.md)
- [Release Notes](../../RELEASE.md)
