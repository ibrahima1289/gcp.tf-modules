# Google Cloud Organization
## What is an Organization in Google Cloud?

A **Google Cloud Organization** is the top-level node in the [Google Cloud Resource Manager hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy):

**Organization → Folder → Project → Resources**

It usually maps to your company domain (for example, `example.com`) through Google Workspace or Cloud Identity.

---

## What does an Organization do?

An Organization provides centralized governance and control:

1. **Top-level ownership and governance**
  - Represents the enterprise boundary for all cloud resources.

2. **IAM inheritance root**
  - IAM policies assigned at Organization level can flow down to folders, projects, and resources.

3. **Organization Policy enforcement**
  - Enforces guardrails globally (for example, restricting allowed regions or external IP behavior).

4. **Centralized audit and security operations**
  - Enables org-level logging sinks, security monitoring, and standardized contact/incident routing.

---

## Why is Organization important?

Without an Organization node, governance becomes fragmented across independent projects. This leads to inconsistent access control, uneven policy enforcement, and weaker visibility.

The Organization layer gives a single control plane for enterprise-wide standards and compliance.

---

## Real-life examples

## 1) Global enterprise baseline controls

**Scenario:** A multinational company wants consistent controls in all regions.

- Set org-level policy to disable risky configurations by default.
- Route audit logs from all descendants to a central security project.

Result: every new project starts with secure defaults and global audit coverage.

## 2) Centralized security team model

**Scenario:** Security team governs cloud access for all departments.

- Security admins receive org-level IAM roles for policy and audit oversight.
- Departments still manage day-to-day resources in their own folders/projects.

Result: clear separation between governance and application ownership.

## 3) Compliance-first operating model

**Scenario:** Organization must satisfy strict regulatory requirements.

- Apply organization-wide policy constraints and logging standards.
- Register essential contacts for billing, legal, and security notifications.

Result: consistent compliance controls across all projects, not just selected ones.

## 4) M&A integration

**Scenario:** New business unit is onboarded after acquisition.

- Place acquired teams under dedicated folders inside the same organization.
- Inherit baseline identity, policy, and monitoring controls automatically.

Result: faster integration with reduced governance drift.

---

## Best practices

- Keep Organization-level permissions minimal and tightly controlled.
- Apply global controls at org level, delegated controls at folder level.
- Use additive IAM patterns to reduce accidental permission removal.
- Centralize logs and security telemetry early.
- Document governance owners and escalation contacts.

---

## Security and operations guidance

- Apply organization-level IAM only to a small set of trusted admins; delegate to folders for day-to-day operations.
- Enable organization-level audit logging sinks to a dedicated log-storage project owned by the security team.
- Use Organization Policy constraints to enforce guardrails globally (e.g., `constraints/compute.requireOsLogin`, `constraints/compute.vmExternalIpAccess`, `constraints/storage.publicAccessPrevention`).
- Register essential contacts (legal, security, billing, technical) at the organization level for incident notifications.
- Review organization-level IAM bindings regularly; remove stale or over-provisioned roles.
- Enable Security Command Center Standard or Premium at org level for centralized threat and misconfiguration detection.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_organization_iam_binding`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam_binding) | Grants IAM roles at the organization level |
| [`google_organization_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_policy) | Enforces constraint-based guardrails org-wide |
| [`google_logging_organization_sink`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | Routes org-level audit logs to GCS, BigQuery, or Pub/Sub |
| [`google_essential_contacts_contact`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/essential_contacts_contact) | Registers notification contacts for billing, security, and legal |
| [`google_folder`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder) | Creates child folders under the organization |

---

## Related Docs

- [GCP Organization Terraform Module README](README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Resource Hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
- [Organization Policy Overview](https://cloud.google.com/resource-manager/docs/organization-policy/overview)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
