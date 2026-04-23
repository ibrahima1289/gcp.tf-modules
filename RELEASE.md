# Release Notes

All notable changes to root markdown documentation in this repository are documented in this file.

> Ordering: newest entries first (latest on top).

## 2026-04-22 — Autoscaling Terraform Module
- Created [GCP Autoscaling module](modules/networking/gcp_autoscaling/README.md) supporting regional and zonal MIG autoscalers with CPU, HTTP LB, custom metric, Pub/Sub, and scheduling signals.
- Added scale-in control to limit VM removal rate and predictive autoscaling via `OPTIMIZE_AVAILABILITY` for pre-scaling before demand.
- Added [Autoscaling deployment plan](tf-plans/gcp_autoscaling/README.md) with CPU, LB, Pub/Sub, scheduled, and GPU zonal examples.
- Updated module count from 14 to 15; added module and plan links to all root markdown files.

## 2026-04-22 — Cloud VPN Terraform Module
- Created [GCP Cloud VPN module](modules/networking/gcp_cloud_vpn/README.md) supporting multiple HA VPN gateways, external peer gateways, IPsec tunnels, Cloud Router interfaces, and BGP peers.
- Added [Cloud VPN deployment plan](tf-plans/gcp_cloud_vpn/README.md) with on-premises and AWS peer examples, shared secret guidance, and post-apply device configuration workflow.
- Updated module count from 13 to 14; added module and plan links to all root markdown files.
- All resources support `create = optional(bool, true)`; tunnels are flattened to `<gateway_key>/<tunnel_key>` keys for stable Terraform state.

## 2026-04-19 — Cloud Logging Terraform Module
- Created [GCP Cloud Logging module](modules/monitoring_devops/gcp_cloud_logging/README.md) supporting custom log buckets, log sinks (GCS, BigQuery, Pub/Sub, log bucket), project-wide log exclusions, and log-based metrics.
- Added [Cloud Logging deployment plan](tf-plans/gcp_cloud_logging/README.md) with examples for all four resource types, sink IAM guidance, and metric filter reference.
- Updated module count from 12 to 13 in the service hierarchy index; added module and plan links to all root markdown files.
- All resources support `create = optional(bool, true)` and common governance labels via `tags`; `writer_identity` outputs enable declarative sink IAM.

## 2026-04-19 — Cloud Monitoring Terraform Module
- Created [GCP Cloud Monitoring module](modules/monitoring_devops/gcp_cloud_monitoring/README.md) supporting notification channels, alert policies (threshold, absent, log-based), uptime checks, and dashboards.
- Added [Cloud Monitoring deployment plan](tf-plans/gcp_cloud_monitoring/README.md) with examples for all four resource types including a CPU alert, log-based error policy, and HTTPS uptime check.
- Updated module count from 11 to 12 in the service hierarchy index; added module and plan links to all root markdown files.
- All resources support `create = optional(bool, true)` and common governance labels via `tags`.

## 2026-04-19 — Monitoring & DevOps Service Explainers
- Created 11 explainers for all `modules/monitoring_devops/` services: Monitoring, Logging, Trace, Profiler, Error Reporting, Audit Logs, Build, Artifact Registry, Deploy, Source Repositories, and Infrastructure Manager.
- Each explainer covers Core Concepts, HCL examples, Terraform resources, and Security Guidance.
- Updated `gcp-module-service-list.md` explainer count from 36 to 47 and added `Monitoring & DevOps` to the domain list.
- Synced all root markdown files with Monitoring & DevOps explainer links and `Related Docs` entries.

## 2026-04-18 — Governance Service Explainers
- Created [Resource Manager explainer](modules/governance/gcp-resource_manager/gcp-resource-manager.md) covering org/folder/project hierarchy, org policies, tags, and liens.
- Created [Cloud Billing explainer](modules/governance/gcp_billing/gcp-billing.md) covering billing accounts, budgets, BigQuery export, and IAM roles.
- Created [Cloud Quotas explainer](modules/governance/gcp_quotas/gcp-quotas.md) covering quota preferences, overrides, monitoring alerts, and common quota limits.
- Created [Labels explainer](modules/governance/gcp_labels/gcp-labels.md) covering label schema, billing attribution, BigQuery queries, and org policy enforcement.

## 2026-04-17 — Cloud SQL
- Created [GCP Cloud SQL module](modules/database/gcp_cloud_sql/README.md) for MySQL, PostgreSQL, and SQL Server with HA, PITR, and private IP.
- Added [Cloud SQL deployment plan](tf-plans/gcp_cloud_sql/README.md) with four example configurations covering all engine types.
- Updated root indexes, service definitions, pricing guide, and deployment guide with Cloud SQL references.
- Cloud SQL supports REGIONAL availability, Query Insights, IAM database auth, and Cloud SQL Auth Proxy connectivity.

## 2026-04-16 — Cloud Identity Groups
- Created [GCP Cloud Identity Groups module](modules/security/gcp_group/README.md) with group creation, membership management, and role assignment.
- Added [Cloud Identity Groups deployment plan](tf-plans/gcp_group/README.md) with two example groups and membership configurations.
- Updated root indexes, service definitions, and deployment guide with Cloud Identity Groups references.
- Cloud Identity Groups enable IAM-at-scale by binding roles to groups rather than individual principals.

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

