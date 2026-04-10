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
| [GCP Folder](modules/hierarchy/folder/README.md) | `modules/hierarchy/folder` | Creates one or many folders with optional nested hierarchy, folder IAM, OrgPolicy v2 constraints, log sinks, and essential contacts. |
| [GCP Project](modules/hierarchy/project/README.md) | `modules/hierarchy/project` | Creates one or many projects with parent validation (org or folder), optional API enablement, labels, and safe lifecycle handling. |

## Deployment Plans

| Plan | Path | Module Used |
|------|------|-------------|
| [GCP Organization](tf-plans/gcp_organization/README.md) | `tf-plans/gcp_organization` | [modules/hierarchy/organization](modules/hierarchy/organization/README.md) |
| [GCP Folder](tf-plans/gcp_folder/README.md) | `tf-plans/gcp_folder` | [modules/hierarchy/folder](modules/hierarchy/folder/README.md) |
| [GCP Project](tf-plans/gcp_project/README.md) | `tf-plans/gcp_project` | [modules/hierarchy/project](modules/hierarchy/project/README.md) |
