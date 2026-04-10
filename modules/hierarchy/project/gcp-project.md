# Google Cloud Project: 

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

## Related Docs

- [GCP Project Terraform Module README](README.md)
- [GCP Project Deployment Plan](../../../tf-plans/gcp_project/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Resource Hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
