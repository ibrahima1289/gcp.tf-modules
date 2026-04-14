# Google Cloud Project

## What is a Project in Google Cloud?

A **Project** is the primary operational boundary in Google Cloud. Most billable services and deployable resources live inside a project.

In hierarchy terms:

**Organization → Folder → Project → Resources**

Projects are where you enable APIs, assign IAM roles, set budgets, and deploy workloads.

---

## What does a Project do?

A Project is the unit for delivery, billing, and isolation:

1. **Resource container**
  - Hosts resources like VMs, GKE clusters, databases, buckets, and serverless services.

2. **Billing and quotas boundary**
  - Links usage to billing accounts and applies project-level quotas.

3. **Access boundary**
  - Project IAM controls who can deploy, operate, or view resources.

4. **API/service activation boundary**
  - APIs are enabled per project (for example, Compute Engine API, Cloud Run API).

---

## Why use separate Projects?

Using one large project for everything makes access, billing, and blast-radius management difficult.

Separate projects provide cleaner isolation for teams, environments, and workloads.

---

## Real-life examples

## 1) Environment isolation (dev/stage/prod)

**Scenario:** A team runs one application across lifecycle environments.

- Project: `app-dev`
- Project: `app-stage`
- Project: `app-prod`

Result: production permissions, quotas, and change controls stay isolated from development.

## 2) Team-based ownership

**Scenario:** Platform and product teams share a cloud foundation.

- Project: `network-shared`
- Project: `security-ops`
- Project: `product-checkout`
- Project: `product-catalog`

Result: each team owns its lifecycle while central teams keep shared services separate.

## 3) Billing transparency

**Scenario:** Finance needs clear cost attribution by product line.

- One project per product or cost center.
- Export billing data by project for showback/chargeback.

Result: accurate accountability and simpler cost optimization.

## 4) Risk and blast-radius control

**Scenario:** Security incident occurs in one workload.

- Affected resources are contained to one project boundary.
- IAM and service accounts from other projects are unaffected.

Result: reduced blast radius and faster incident response.

---

## Best practices

- Use separate projects for production and non-production.
- Enable only required APIs per project.
- Apply least-privilege IAM at project level.
- Standardize labels for cost and ownership (`owner`, `environment`, `cost_center`).
- Use `prevent_destroy` safeguards for critical projects.

---

## Security and operations guidance

- Enable only the APIs required for the project's workloads; disable unused APIs to reduce attack surface.
- Apply least-privilege IAM at the project level; prefer folder-level grants for shared team access.
- Standardize project labels (`owner`, `environment`, `cost_center`, `team`) for cost attribution and governance.
- Use `lifecycle { prevent_destroy = true }` in Terraform for production projects to prevent accidental deletion.
- Link projects to the correct billing account and set project-level budgets and alerts.
- Configure a project-level log sink to export audit logs to the centralized log project.
- Avoid using the default service account; create dedicated least-privilege SAs per workload.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_project`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project) | Creates a GCP project with billing account, folder, and labels |
| [`google_project_iam_binding`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_binding) | Grants IAM roles at the project level |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables a specific Google Cloud API in the project |
| [`google_project_default_service_accounts`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_default_service_accounts) | Controls default service account behavior |
| [`google_logging_project_sink`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) | Routes project-level logs to GCS, BigQuery, or Pub/Sub |
| [`google_billing_budget`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | Sets budget alerts for project spend |

---

## Related Docs

- [GCP Project Terraform Module README](README.md)
- [GCP Project Deployment Plan](../../../tf-plans/gcp_project/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Resource Hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
