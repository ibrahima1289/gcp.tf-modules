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

---

## Service Explainer Documents

| Category | Path | Description |
|----------|------|-------------|
| [Hierarchy Explainers](modules/hierarchy/) | `modules/hierarchy` | Practical explainers for organization, folder, and project service concepts and implementation patterns. |
| [Compute Explainers](modules/compute/) | `modules/compute` | Practical explainers for VM, GKE, Cloud Run, App Engine, and Batch real-world usage. |
| [Storage Explainers](modules/storage/) | `modules/storage` | Practical explainers for object, file, block, backup, and performance storage service choices. |
| [Networking Explainers](modules/networking/) | `modules/networking` | Practical explainers for VPC, subnetworks, DNS, VPN, NAT, routing, and traffic management services. |
