# Google Cloud Advisory Notifications

Google Cloud Advisory Notifications is a managed service that delivers security bulletins, incident notifications, and product advisory messages directly to designated contacts within a Google Cloud organization. It centralizes the delivery of critical operational and compliance communications that were previously scattered across email lists, support portals, and console banners.

> Back to [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Overview

Advisory Notifications aggregates notifications from multiple Google systems — security vulnerability disclosures, deprecation notices, incident post-mortems, and compliance advisories — into a single API-accessible and console-accessible feed. Organizations configure notification recipients at the organization or project level, and notifications are routed automatically based on scope.

| Notification Source | Examples |
|--------------------|---------|
| **Security bulletins** | Vulnerability disclosures affecting GKE nodes, OS images, or managed services |
| **Incident notices** | Service disruptions, data processing events, and impact reports |
| **Deprecation notices** | API version deprecations, runtime EOL announcements |
| **Compliance advisories** | Regulatory or policy change notifications affecting organization resources |
| **Product updates** | Breaking change warnings and migration guidance |

---

## Core Concepts

### Notification Types

Advisory Notifications groups communications into typed categories. Each type has its own notification settings and can be subscribed to independently.

| Type ID | Description |
|---------|-------------|
| `NOTIFICATION_TYPE_SECURITY_PRIVACY_ADVISORY` | Security and privacy vulnerability bulletins |
| `NOTIFICATION_TYPE_SENSITIVE_ACTIONS` | Sensitive actions detected in the organization (e.g. policy changes, key deletions) |
| `NOTIFICATION_TYPE_SECURITY_MSA` | Mandatory security announcements from Google |
| `NOTIFICATION_TYPE_NOTIFICATION_PERSONNEL_CHANGE` | Changes to notification contact personnel |

### Notification Settings

Settings are configured per notification type, per resource scope (organization or project). A setting defines the set of recipient email addresses for a given type.

```
Organization
  └── NotificationSetting (per type)
        ├── notificationType: SECURITY_PRIVACY_ADVISORY
        └── recipients: [{ email: "security-team@example.com" }]
```

### Subscriptions vs. Settings

| Concept | Description |
|---------|-------------|
| **Settings** | Configuration objects that define who receives a given notification type on a resource. Managed via the API/Terraform. |
| **Subscriptions** | Read-only objects representing active delivery channels derived from settings. Managed by the service. |

---

## Resource Hierarchy

Advisory Notifications settings can be scoped at two levels:

| Scope | Resource Format | Notes |
|-------|----------------|-------|
| **Organization** | `organizations/{org_id}` | Settings apply to all projects in the org |
| **Project** | `projects/{project_id_or_number}` | Settings apply to the specific project only |

Org-level settings are inherited by projects unless project-level settings explicitly override them.

---

## Notification Delivery

Notifications are delivered via:

- **Email** — to the recipient addresses configured in the notification settings
- **Google Cloud Console** — displayed in the Notifications panel for users with appropriate IAM access
- **API** — programmatic listing and acknowledgement of notifications via the Advisory Notifications API

Notifications are **not delivered to Pub/Sub or webhooks** natively. For integration with alerting pipelines, organizations typically poll the API or use Essential Contacts in conjunction with Advisory Notifications.

---

## Relationship with Essential Contacts

Essential Contacts (`google_essential_contacts_contact`) is a related service that registers contacts for broad operational categories (security, billing, legal, technical). Advisory Notifications provides more granular, type-specific recipient configuration and is the recommended mechanism for security advisory routing.

| Feature | Essential Contacts | Advisory Notifications |
|---------|-------------------|----------------------|
| **Scope** | Org, folder, project | Org, project |
| **Categories** | Broad (security, billing, legal, etc.) | Fine-grained notification types |
| **Delivery** | Email | Email + console + API |
| **Terraform resource** | `google_essential_contacts_contact` | `google_advisory_notifications_settings` |

---

## Security and Operations Guidance

- Configure advisory notification settings at the **organization level** so that all projects receive security bulletins without per-project configuration.
- Route `SECURITY_PRIVACY_ADVISORY` and `SECURITY_MSA` types to a dedicated **security distribution list**, not individual email addresses, to avoid single points of failure.
- Combine Advisory Notifications with **Essential Contacts** for comprehensive coverage — Essential Contacts handles billing and legal; Advisory Notifications handles security advisories.
- Periodically audit notification settings to ensure recipient addresses are still valid and monitored.
- Use the Advisory Notifications API to programmatically list and acknowledge notifications as part of incident response automation.
- Treat mandatory security announcements (`SECURITY_MSA`) as high-priority — these are non-optional communications from Google about critical security events.

---

## Terraform Resources

| Resource | Description | Terraform Registry |
|----------|-------------|-------------------|
| `google_advisory_notifications_settings` | Configures notification recipients for a specific notification type on an organization or project | [Link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/advisory_notifications_settings) |

---

## Related Docs

- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../gcp-service-list-definitions.md)
- [GCP IAM Service Explainer](../gcp_iam/gcp-iam.md)
- [GCP Secret Manager Service Explainer](../gcp_secret_manager/gcp-secret-manager.md)
- [Release Notes](../../RELEASE.md)
