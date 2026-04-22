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
| [GCP Subnetworks](modules/networking/gcp_subnetworks/README.md) | `modules/networking/gcp_subnetworks` | Creates one or many regional VPC subnetworks with secondary ranges, private Google access, and optional VPC Flow Logs. |
| [GCP Networks (VPC)](modules/networking/gcp_networks/README.md) | `modules/networking/gcp_networks` | Creates one or many custom-mode VPC networks with configurable routing mode, MTU, internal IPv6, firewall policy order, and optional Shared VPC host registration. |
| [GCP Cloud NAT](modules/networking/gcp_cloud_nat/README.md) | `modules/networking/gcp_cloud_nat` | Creates one or many Cloud NAT configurations with optional router creation, manual/auto NAT IP allocation, and logging controls. |
| [GCP Cloud Router](modules/networking/gcp_cloud_router/README.md) | `modules/networking/gcp_cloud_router` | Creates one or many Cloud Routers with optional BGP interfaces and peers for VPN, Interconnect, and custom route advertisement. |
| [GCP Cloud VPN](modules/networking/gcp_cloud_vpn/README.md) | `modules/networking/gcp_cloud_vpn` | Creates HA VPN gateways, external peer gateways, IPsec tunnels, Cloud Router interfaces, and BGP peers for encrypted hybrid and multi-cloud connectivity. |
| [GCP IAM](modules/security/gcp_iam/README.md) | `modules/security/gcp_iam` | Creates service accounts, custom IAM roles, and authoritative or additive IAM bindings across project, folder, and organization scopes. |
| [GCP Cloud Storage](modules/storage/gcp_cloud_storage/README.md) | `modules/storage/gcp_cloud_storage` | Creates one or many Cloud Storage buckets with lifecycle rules, versioning, CMEK, logging, CORS, website hosting, autoclass, and soft-delete controls. |
| [GCP Cloud Identity Groups](modules/security/gcp_group/README.md) | `modules/security/gcp_group` | Creates Cloud Identity groups with memberships and role assignments for IAM-at-scale governance. |
| [GCP Cloud SQL](modules/database/gcp_cloud_sql/README.md) | `modules/database/gcp_cloud_sql` | Creates one or many Cloud SQL instances (MySQL, PostgreSQL, SQL Server) with databases, users, backups, private IP, Query Insights, and maintenance window controls. |
| [GCP Cloud Monitoring](modules/monitoring_devops/gcp_cloud_monitoring/README.md) | `modules/monitoring_devops/gcp_cloud_monitoring` | Creates notification channels, alert policies (threshold, absent, log-based), uptime checks (HTTP/S and TCP), and dashboards for a GCP project. |
| [GCP Cloud Logging](modules/monitoring_devops/gcp_cloud_logging/README.md) | `modules/monitoring_devops/gcp_cloud_logging` | Creates custom log buckets, log sinks (GCS, BigQuery, Pub/Sub, log bucket), project-wide log exclusions, and log-based metrics for Cloud Monitoring. |

## Deployment Plans

| Plan | Path | Module Used |
|------|------|-------------|
| [GCP Organization](tf-plans/gcp_organization/README.md) | `tf-plans/gcp_organization` | [modules/hierarchy/organization](modules/hierarchy/organization/README.md) |
| [GCP Folder](tf-plans/gcp_folder/README.md) | `tf-plans/gcp_folder` | [modules/hierarchy/folder](modules/hierarchy/folder/README.md) |
| [GCP Project](tf-plans/gcp_project/README.md) | `tf-plans/gcp_project` | [modules/hierarchy/project](modules/hierarchy/project/README.md) |
| [GCP Subnetworks](tf-plans/gcp_subnetworks/README.md) | `tf-plans/gcp_subnetworks` | [modules/networking/gcp_subnetworks](modules/networking/gcp_subnetworks/README.md) |
| [GCP Networks (VPC)](tf-plans/gcp_networks/README.md) | `tf-plans/gcp_networks` | [modules/networking/gcp_networks](modules/networking/gcp_networks/README.md) |
| [GCP Cloud NAT](tf-plans/gcp_cloud_nat/README.md) | `tf-plans/gcp_cloud_nat` | [modules/networking/gcp_cloud_nat](modules/networking/gcp_cloud_nat/README.md) |
| [GCP Cloud Router](tf-plans/gcp_cloud_router/README.md) | `tf-plans/gcp_cloud_router` | [modules/networking/gcp_cloud_router](modules/networking/gcp_cloud_router/README.md) |
| [GCP Cloud VPN](tf-plans/gcp_cloud_vpn/README.md) | `tf-plans/gcp_cloud_vpn` | [modules/networking/gcp_cloud_vpn](modules/networking/gcp_cloud_vpn/README.md) |
| [GCP IAM](tf-plans/gcp_iam/README.md) | `tf-plans/gcp_iam` | [modules/security/gcp_iam](modules/security/gcp_iam/README.md) |
| [GCP Cloud Storage](tf-plans/gcp_cloud_storage/README.md) | `tf-plans/gcp_cloud_storage` | [modules/storage/gcp_cloud_storage](modules/storage/gcp_cloud_storage/README.md) |
| [GCP Cloud Identity Groups](tf-plans/gcp_group/README.md) | `tf-plans/gcp_group` | [modules/security/gcp_group](modules/security/gcp_group/README.md) |
| [GCP Cloud SQL](tf-plans/gcp_cloud_sql/README.md) | `tf-plans/gcp_cloud_sql` | [modules/database/gcp_cloud_sql](modules/database/gcp_cloud_sql/README.md) |
| [GCP Cloud Monitoring](tf-plans/gcp_cloud_monitoring/README.md) | `tf-plans/gcp_cloud_monitoring` | [modules/monitoring_devops/gcp_cloud_monitoring](modules/monitoring_devops/gcp_cloud_monitoring/README.md) |
| [GCP Cloud Logging](tf-plans/gcp_cloud_logging/README.md) | `tf-plans/gcp_cloud_logging` | [modules/monitoring_devops/gcp_cloud_logging](modules/monitoring_devops/gcp_cloud_logging/README.md) |

---

## Service Explainer Documents

| Category | Path | Description |
|----------|------|-------------|
| [Hierarchy Explainers](modules/hierarchy/) | `modules/hierarchy` | Practical explainers for organization, folder, and project service concepts and implementation patterns. |
| [Compute Explainers](modules/compute/) | `modules/compute` | Practical explainers for VM, GKE, Cloud Run, App Engine, and Batch real-world usage. |
| [Storage Explainers](modules/storage/) | `modules/storage` | Practical explainers for Cloud Storage, Filestore, Persistent Disk, Hyperdisk, backup, and performance storage choices. |
| [Networking Explainers](modules/networking/) | `modules/networking` | Practical explainers for VPC, subnetworks, DNS, VPN, NAT, routing, and traffic management services. |
| [Security Explainers](modules/security/) | `modules/security` | Practical explainers for IAM, Cloud Identity Groups, KMS, Secret Manager, Certificate Authority Service, Certificate Manager, Advisory Notifications, and related security services. |
| [Database Explainers](modules/database/) | `modules/database` | Practical explainers for Cloud SQL, AlloyDB, Spanner, Firestore, Bigtable, Memorystore, Datastream, and Database Migration Service. |
| [Governance Explainers](modules/governance/) | `modules/governance` | Practical explainers for Resource Manager, Cloud Billing, Cloud Quotas, and Labels. |
| [Monitoring & DevOps Explainers](modules/monitoring_devops/) | `modules/monitoring_devops` | Practical explainers for Cloud Monitoring, Logging, Trace, Profiler, Error Reporting, Audit Logs, Cloud Build, Artifact Registry, Cloud Deploy, Source Repositories, and Infrastructure Manager. |
