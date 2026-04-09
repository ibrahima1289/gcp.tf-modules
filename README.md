# gcp.tf-modules
Terraform Modules for Google Cloud services. This repo is used only for learning purpose; do not use as a reference for production deployment(s).

## Root Documentation Index

| Document | Description |
|----------|-------------|
| [GCP Module & Service Hierarchy](gcp-module-service-list.md) | Service-domain hierarchy and Google Cloud Resource Manager hierarchy (Organization → Folder → Project → Resources). |
| [Google Cloud Service List — Definitions](gcp-service-list-definitions.md) | Category-based list of major Google Cloud services with concise definitions. |
| [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md) | Practical pricing model overview, cost examples, and optimization guidance. |
| [Terraform Deployment Guide (CLI + GitHub Actions)](gcp-terraform-deployment-cli-github-actions.md) | End-to-end setup for deploying Google Cloud resources with Terraform from local CLI and GitHub Actions (OIDC). |
| [Release Notes](RELEASE.md) | Repository release history for root documentation updates. |

---

## Terraform Modules

| Module | Path | Description |
|--------|------|-------------|
| [GCP Organization](modules/hierarchy/organization/README.md) | `modules/hierarchy/organization` | Manages org-level IAM, OrgPolicy v2 constraints, log sinks, and essential contacts. Org node is looked up via data source. |

## Deployment Plans

| Plan | Path | Module Used |
|------|------|-------------|
| [GCP Organization](tf-plans/gcp_organization/README.md) | `tf-plans/gcp_organization` | [modules/hierarchy/organization](modules/hierarchy/organization/README.md) |
