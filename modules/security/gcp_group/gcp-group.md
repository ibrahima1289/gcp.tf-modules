# Google Cloud Identity Groups

Google Cloud Identity Groups is a managed group service that organizes users, service accounts, and other groups into named collections for IAM policy assignment, access management, and organizational governance. Groups are the recommended mechanism for granting IAM access to sets of users — binding roles to groups rather than individual principals simplifies access management and reduces policy sprawl.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

A Cloud Identity Group is a collection of members (users, service accounts, or other groups) identified by a group email address. IAM policies can reference a group using the `group:engineers@example.com` principal format. Adding or removing a user from the group is the only change needed to update their effective permissions across all resources where the group has IAM bindings — no Terraform changes required.

| Capability | Description |
|-----------|-------------|
| **IAM delegation** | Grant IAM roles to a group once; manage membership separately |
| **Nested groups** | Groups can contain other groups for hierarchical access structures |
| **Dynamic membership** | CEL-based membership rules for attribute-driven group population |
| **Security groups** | Designated as security-sensitive; restricted membership management |
| **Group types** | Discussion forums, linked (Workspace/external) groups, security groups |
| **Google Workspace integration** | Groups created in Workspace are usable in Google Cloud IAM natively |

---

## Core Concepts

### Group Identity

Every group has a unique email address that serves as its identifier in IAM policy bindings:

```
group:devops-team@example.com
group:data-engineers@example.com
group:gke-admins@example.com
```

The group email is the stable reference used in all IAM policy documents. Group membership changes do not affect the IAM policy itself.

### Group Types

| Type | Label | Description |
|------|-------|-------------|
| **Discussion group** | `DISCUSSION_FORUM` | General-purpose mailing list; default type |
| **Linked group** | `LINKED_IDENTITY_SOURCE` | Synced from an external identity provider |
| **Security group** | `SECURITY` | Hardened group intended for access control; membership changes are audited and restricted |
| **Dynamic group** | `DYNAMIC_GROUP` | Membership populated automatically by CEL expression |

> Security groups (`SECURITY` label) are the recommended type for any group used in IAM bindings. They enforce stricter governance around membership management.

### Membership Types

| Member Type | Format | Notes |
|-------------|--------|-------|
| User account | `user:alice@example.com` | Google account or Cloud Identity user |
| Service account | `serviceAccount:sa@project.iam.gserviceaccount.com` | Workload identity |
| Nested group | `group:sub-team@example.com` | Inherits all parent group's IAM roles |
| External member | External email | Supported in some group configurations depending on org policy |

### Dynamic Group Membership

Dynamic groups use CEL (Common Expression Language) expressions to define membership criteria based on user attributes from the identity directory:

```
# Members whose department attribute is "engineering"
member.department == "engineering"

# Members in a specific cost center
member.costCenter == "CC-1234"

# Members with a specific custom attribute
member.customAttributes.team == "platform"
```

Dynamic membership is evaluated periodically and updated automatically as directory attributes change.

---

## Group Hierarchy and Nesting

Groups can be nested to create access inheritance trees:

```
group:org-admins@example.com
  └── group:platform-team@example.com
        ├── user:alice@example.com
        └── user:bob@example.com

group:developers@example.com
  ├── group:frontend-devs@example.com
  │     └── user:carol@example.com
  └── group:backend-devs@example.com
        └── user:dave@example.com
```

IAM roles granted to `org-admins` apply transitively to all nested members. Nesting depth is subject to Google limits (typically up to 10 levels).

---

## Groups vs. Direct User Bindings

| Approach | IAM Policy Changes on Joiners/Leavers | Scale | Recommended |
|----------|--------------------------------------|-------|------------|
| **Group binding** | None — only group membership changes | Scales to thousands of users | ✅ Yes |
| **Individual user binding** | Add/remove policy binding per user | Bloats policy; hard to audit | ❌ No |

Binding roles to groups instead of individuals:
- Reduces the number of IAM bindings per resource
- Centralizes access reviews to group membership audits
- Eliminates the need to update IAM policies when individuals join or leave teams

---

## Access Control for Groups

Managing groups themselves requires IAM roles on the Groups resource:

| Role | Permissions | Use Case |
|------|------------|---------|
| `roles/cloudidentity.groups.admin` | Create, update, delete groups; manage membership | Group administrators |
| `roles/cloudidentity.groups.editor` | Update group settings and membership | Group owners/managers |
| `roles/cloudidentity.groups.viewer` | View group membership and metadata | Auditing |
| `roles/cloudidentity.viewer` | Read-only view of Cloud Identity resources | Compliance review |

Group membership management can also be delegated to specific group owners without granting broad admin roles.

---

## Integration with IAM

Groups integrate with IAM as first-class principals. The full principal type matrix for groups:

| Principal Format | Description |
|-----------------|-------------|
| `group:engineers@example.com` | All current members of the group |
| `groupWithContext:engineers@example.com` | Group with context-aware access conditions (BeyondCorp) |

Groups used in IAM policies must be associated with the same Google Workspace or Cloud Identity domain as the organization, or explicitly allowed as external members via org policy.

---

## Audit Logging

Group management operations are captured in Cloud Audit Logs:

| Log Type | Events Captured |
|----------|----------------|
| **Admin Activity** | Group creation, deletion, label changes, membership additions and removals | Always on |
| **Data Access** | Group membership reads, policy reads | Enable for compliance environments |

Security group membership changes are additionally subject to access approvals if configured, creating a two-party authorization model for sensitive group modifications.

---

## Security and Operations Guidance

- Use **security groups** (`SECURITY` label) for any group referenced in IAM bindings — this enforces membership governance and audit trails.
- Prefer **group bindings over individual user bindings** in all IAM policies to keep policies stable and auditable.
- Use **nested groups** to model organizational hierarchy but limit nesting depth to avoid complex transitive permission paths that are hard to reason about.
- Implement **dynamic groups** for role-based access tied to HR system attributes (department, job function, cost center) to automate joiners/movers/leavers workflows.
- Conduct **periodic access reviews** by auditing group membership rather than IAM policy bindings — membership is the source of truth for who has access.
- Apply **Organization Policy** (`constraints/iam.allowedPolicyMemberDomains`) to restrict which domains can be added as group members or IAM principals.
- Never add `allUsers` or `allAuthenticatedUsers` to a security group used for production IAM bindings.
- Use **Cloud Identity Groups API** or Terraform to manage group membership programmatically and maintain it in version control.
- Monitor for unexpected group membership changes using Cloud Monitoring alerts on Admin Activity audit logs.
- Document group purpose, owner, and review cadence in group descriptions to simplify governance.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_cloud_identity_group` | Creates a Cloud Identity group with type labels | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) |
| `google_cloud_identity_group_membership` | Adds a member (user, SA, or group) to a group | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) |
| `google_cloud_identity_group_lookup` | Data source to look up a group by email | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_identity_group_lookup) |
| `google_cloud_identity_group_memberships` | Data source to list all members of a group | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_identity_group_memberships) |

---

## Related Docs

- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [GCP IAM Service Explainer](../gcp_iam/gcp-iam.md)
- [GCP Advisory Notifications Service Explainer](../gcp_advisory_notification/gcp-advisory-notification.md)
- [Release Notes](../../RELEASE.md)
