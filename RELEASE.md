# Release Notes

All notable changes to root markdown documentation in this repository are documented in this file.

> Ordering: newest entries first (latest on top).

## 2026-04-09

### Added
- GCP Organization Terraform module (`modules/hierarchy/organization/`) — data source lookup, additive IAM members, OrgPolicy v2 constraints, organization-level log sinks, and essential contacts.
- Deployment plan wrapper (`tf-plans/gcp_organization/`) — `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `locals.tf`, `terraform.tfvars`, and `README.md`.
- Module README with architecture diagram, variable/output tables, usage example, and log sink writer identity notes.

### Updated
- [README](README.md) — added Terraform Modules and Deployment Plans index tables.
- [GCP Module & Service Hierarchy](gcp-module-service-list.md) — updated Coverage Summary (Terraform Modules in repo: 1), expanded Organization row with module resources and module link.
- [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md) — added Organization Policy, Essential Contacts, and Resource Manager pricing rows to Security, Identity & Governance table.

## 2026-04-08

### Added
- [Terraform Deployment Guide (CLI + GitHub Actions)](gcp-terraform-deployment-cli-github-actions.md).

### Updated
- Added deployment guide link to [README](README.md) root documentation index.
- Added explicit `gcloud` installation steps (Windows/macOS/Linux) and section renumbering in [Terraform Deployment Guide (CLI + GitHub Actions)](gcp-terraform-deployment-cli-github-actions.md).
- Converted Service Hierarchy bullet list to per-domain tables in [GCP Module & Service Hierarchy](gcp-module-service-list.md) with Terraform support column (✅ Full / ⚠️ Partial / ❌ None) and Terraform Registry resource links.

## 2026-04-07

### Added
- Root documentation index in [README](README.md).
- [Google Cloud Service List — Definitions](gcp-service-list-definitions.md).
- [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md).
- [GCP Module & Service Hierarchy](gcp-module-service-list.md).

### Updated
- Added Google Cloud Resource Manager hierarchy documentation:
	- Organization → Folder → Project → Resources.
- Added cross-links between all root documentation files.
- Normalized root docs navigation with consistent Related Docs sections.

