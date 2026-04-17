# Release Notes

All notable changes to root markdown documentation in this repository are documented in this file.

> Ordering: newest entries first (latest on top).

## 2026-04-15 — Cloud Storage
- Created [GCP Cloud Storage module](modules/storage/gcp_cloud_storage/README.md) with versioning, lifecycle, CMEK, CORS, and autoclass.
- Added [Cloud Storage deployment plan](tf-plans/gcp_cloud_storage/README.md) with two example bucket configurations.
- Updated root indexes, service definitions, pricing guide, and deployment guide with Cloud Storage references.
- Created [Cloud Identity Groups service explainer](modules/security/gcp_group/gcp-group.md) and five other security explainers.

## 2026-04-14
- Created [GCP IAM module](modules/security/gcp_iam/README.md) with service accounts, custom roles, and IAM bindings across project, folder, and org.
- Added [GCP IAM deployment plan](tf-plans/gcp_iam/README.md) with wrapper files, two example configurations (CI/CD pipeline SA + folder-scoped member), and documented apply workflow.
- Created [GCP IAM service explainer](modules/security/gcp_iam/gcp-iam.md) covering principals, roles, policy inheritance, custom roles, and audit logging.
- Updated root indexes, service definitions, pricing guide, and deployment guide to include IAM module and plan references.

## 2026-04-13
- Created [GCP Cloud Router module](modules/networking/gcp_cloud_router/README.md) supporting multi-router deployments, optional BGP interfaces and peers, BFD, and custom route advertisement.
- Added [GCP Cloud Router deployment plan](tf-plans/gcp_cloud_router/README.md) with wrapper files, two example configurations, and documented apply workflow.
- Updated root indexes, service definitions, pricing guide, and deployment guide to include Cloud Router module and plan references.
- Standardized all service explainer documents with consistent section headings, security guidance bullets, and corrected cross-reference links.

## 2026-04-11
- Published [GCP Networks (VPC) module](modules/networking/gcp_networks/README.md) supporting multi-network creation, custom-mode routing, MTU controls, IPv6 options, and Shared VPC hosting.
- Published [GCP Networks (VPC) deployment plan](tf-plans/gcp_networks/README.md) with wrapper files, examples, and documented apply workflow for repeatable provisioning.
- Published [GCP Subnetworks module](modules/networking/gcp_subnetworks/README.md) enabling multi-subnet definitions, secondary ranges, Private Google Access, and optional VPC Flow Logs.
- Updated [README](README.md), [Service Hierarchy](gcp-module-service-list.md), [Definitions](gcp-service-list-definitions.md), [Pricing](gcp-services-pricing-guide.md), and [Deployment Guide](gcp-terraform-deployment-cli-github-actions.md) to reference renamed networking modules and plans.

## 2026-04-10

- Expanded [Organization](modules/hierarchy/organization/README.md), [Folder](modules/hierarchy/folder/README.md), and [Project](modules/hierarchy/project/README.md) module READMEs with architecture diagrams, validations, examples, and operational guidance.
- Added [Project deployment plan](tf-plans/gcp_project/README.md) documentation covering wrapper structure, required inputs, optional settings, and output consumption patterns.
- Refreshed [README](README.md) module and plan indexes to include project hierarchy components and consistent navigation links.
- Aligned cross-document references across [Definitions](gcp-service-list-definitions.md), [Pricing](gcp-services-pricing-guide.md), and [Deployment Guide](gcp-terraform-deployment-cli-github-actions.md) for accurate project-level hierarchy documentation coverage.

## 2026-04-09

- Published [GCP Organization module](modules/hierarchy/organization/README.md) supporting IAM memberships, OrgPolicy v2 constraints, log sinks, and essential contact management.
- Published [GCP Folder module](modules/hierarchy/folder/README.md) with multi-folder creation, nested hierarchy support, IAM bindings, policies, sinks, and contacts.
- Added deployment wrappers [gcp_organization](tf-plans/gcp_organization/README.md) and [gcp_folder](tf-plans/gcp_folder/README.md), including standard Terraform files, examples, and clear usage instructions.
- Updated [README](README.md), [Service Hierarchy](gcp-module-service-list.md), and [Pricing Guide](gcp-services-pricing-guide.md) to reflect governance modules and folder hierarchy coverage.

## 2026-04-08

- Added [Terraform Deployment Guide](gcp-terraform-deployment-cli-github-actions.md) describing local CLI and GitHub Actions workflows using secure Google Cloud authentication patterns.
- Updated [README](README.md) documentation index to surface deployment guidance alongside hierarchy, definitions, pricing, and release notes.
- Expanded deployment guide with explicit `gcloud` installation steps for Windows, macOS, and Linux environment users.
- Converted hierarchy documentation into service-domain tables within [GCP Module & Service Hierarchy](gcp-module-service-list.md), including Terraform support status and resource links.

## 2026-04-07

- Created root [README](README.md) documentation index to centralize navigation across all primary Google Cloud repository guides.
- Added [Service Definitions](gcp-service-list-definitions.md) covering major Google Cloud services grouped by domain with concise practical descriptions.
- Added [Pricing Guide](gcp-services-pricing-guide.md) summarizing pricing models, key cost drivers, and optimization tips across commonly used services.
- Added [Module & Service Hierarchy](gcp-module-service-list.md) documenting organization-folder-project inheritance, service taxonomy, and cross-links between foundational root documents.

