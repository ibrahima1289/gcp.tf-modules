# GCP Resource Hierarchy Requirements

This document maps every module and its Terraform resources to the GCP hierarchy
scope at which each resource is anchored — **Organization**, **Folder**, or **Project**.

> **Legend**
> - ✅ Required — the resource is scoped to this level
> - ✴️ Optional — the resource can be scoped to this level but is not required
> - ➖ Not applicable

---

## Hierarchy

| Name | Module | Resource | Organization | Folder | Project |
|------|--------|----------|:---:|:---:|:---:|
| Organization IAM Binding | `hierarchy/organization` | `google_organization_iam_binding` | ✅ | ➖ | ➖ |
| Organization IAM Member | `hierarchy/organization` | `google_organization_iam_member` | ✅ | ➖ | ➖ |
| Organization Policy | `hierarchy/organization` | `google_organization_policy` | ✅ | ➖ | ➖ |
| Folder | `hierarchy/folder` | `google_folder` | ✅ (parent) | ✴️ (parent) | ➖ |
| Folder IAM Binding | `hierarchy/folder` | `google_folder_iam_binding` | ➖ | ✅ | ➖ |
| Folder IAM Member | `hierarchy/folder` | `google_folder_iam_member` | ➖ | ✅ | ➖ |
| Project | `hierarchy/project` | `google_project` | ✅ (parent) | ✴️ (parent) | ➖ |
| Project Service (API) | `hierarchy/project` | `google_project_service` | ➖ | ➖ | ✅ |

---

## Security

| Name | Module | Resource | Organization | Folder | Project |
|------|--------|----------|:---:|:---:|:---:|
| Cloud Identity Group | `security/gcp_group` | `google_cloud_identity_group` | ✅ (`customer_id`) | ➖ | ➖ |
| Cloud Identity Group Membership | `security/gcp_group` | `google_cloud_identity_group_membership` | ✅ (`customer_id`) | ➖ | ➖ |
| Project IAM Binding | `security/gcp_iam` | `google_project_iam_binding` | ➖ | ➖ | ✅ |
| Project IAM Member | `security/gcp_iam` | `google_project_iam_member` | ➖ | ➖ | ✅ |
| Project IAM Custom Role | `security/gcp_iam` | `google_project_iam_custom_role` | ➖ | ➖ | ✅ |
| KMS Key Ring | `security/gcp_cloud_kms` | `google_kms_key_ring` | ➖ | ➖ | ✅ |
| KMS Crypto Key | `security/gcp_cloud_kms` | `google_kms_crypto_key` | ➖ | ➖ | ✅ |
| KMS Crypto Key IAM Binding | `security/gcp_cloud_kms` | `google_kms_crypto_key_iam_binding` | ➖ | ➖ | ✅ |
| Secret | `security/gcp_secret_manager` | `google_secret_manager_secret` | ➖ | ➖ | ✅ |
| Secret Version | `security/gcp_secret_manager` | `google_secret_manager_secret_version` | ➖ | ➖ | ✅ |
| Certificate | `security/gcp_certificate_manager` | `google_certificate_manager_certificate` | ➖ | ➖ | ✅ |
| DNS Authorization | `security/gcp_certificate_manager` | `google_certificate_manager_dns_authorization` | ➖ | ➖ | ✅ |
| CA Pool | `security/gcp_certificate_authority` | `google_privateca_ca_pool` | ➖ | ➖ | ✅ |
| Certificate Authority | `security/gcp_certificate_authority` | `google_privateca_certificate_authority` | ➖ | ➖ | ✅ |
| Essential Contact | `security/gcp_advisory_notification` | `google_essential_contacts_contact` | ✴️ | ✴️ | ✅ |

---

## Networking

| Name | Module | Resource | Organization | Folder | Project |
|------|--------|----------|:---:|:---:|:---:|
| VPC Network | `networking/gcp_networks` | `google_compute_network` | ➖ | ➖ | ✅ |
| Subnetwork | `networking/gcp_subnetworks` | `google_compute_subnetwork` | ➖ | ➖ | ✅ |
| Cloud Router | `networking/gcp_cloud_router` | `google_compute_router` | ➖ | ➖ | ✅ |
| Cloud NAT | `networking/gcp_cloud_nat` | `google_compute_router_nat` | ➖ | ➖ | ✅ |
| DNS Managed Zone | `networking/gcp_cloud_dns` | `google_dns_managed_zone` | ➖ | ➖ | ✅ |
| DNS Record Set | `networking/gcp_cloud_dns` | `google_dns_record_set` | ➖ | ➖ | ✅ |
| VPN Gateway | `networking/gcp_cloud_vpn` | `google_compute_vpn_gateway` | ➖ | ➖ | ✅ |
| VPN Tunnel | `networking/gcp_cloud_vpn` | `google_compute_vpn_tunnel` | ➖ | ➖ | ✅ |
| Interconnect Attachment | `networking/gcp_cloud_interconnect` | `google_compute_interconnect_attachment` | ➖ | ➖ | ✅ |
| CDN Backend Bucket | `networking/gcp_cloud_cdn` | `google_compute_backend_bucket` | ➖ | ➖ | ✅ |
| Forwarding Rule | `networking/gcp_cloud_load_balancer` | `google_compute_forwarding_rule` | ➖ | ➖ | ✅ |
| Target HTTP Proxy | `networking/gcp_cloud_load_balancer` | `google_compute_target_http_proxy` | ➖ | ➖ | ✅ |
| URL Map | `networking/gcp_cloud_load_balancer` | `google_compute_url_map` | ➖ | ➖ | ✅ |
| Network Services Gateway | `networking/gcp_traffic_director` | `google_network_services_gateway` | ➖ | ➖ | ✅ |
| Network Connectivity Hub | `networking/gcp_network_connectivity_center` | `google_network_connectivity_hub` | ➖ | ➖ | ✅ |
| Network Connectivity Spoke | `networking/gcp_network_connectivity_center` | `google_network_connectivity_spoke` | ➖ | ➖ | ✅ |

---

## Storage

| Name | Module | Resource | Organization | Folder | Project |
|------|--------|----------|:---:|:---:|:---:|
| Cloud Storage Bucket | `storage/gcp_cloud_storage` | `google_storage_bucket` | ➖ | ➖ | ✅ |
| Storage Bucket IAM Binding | `storage/gcp_cloud_storage` | `google_storage_bucket_iam_binding` | ➖ | ➖ | ✅ |
| Persistent Disk | `storage/gcp_persistent_disk` | `google_compute_disk` | ➖ | ➖ | ✅ |
| Hyperdisk | `storage/gcp_hyperdisk` | `google_compute_disk` (hyperdisk type) | ➖ | ➖ | ✅ |
| Local SSD | `storage/gcp_local_ssd` | `google_compute_instance` (local SSD) | ➖ | ➖ | ✅ |
| Filestore Instance | `storage/gcp_cloud_filestore` | `google_filestore_instance` | ➖ | ➖ | ✅ |
| Backup & DR Management Server | `storage/gcp_backup_and_DR_services` | `google_backup_dr_management_server` | ➖ | ➖ | ✅ |

---

## Compute

| Name | Module | Resource | Organization | Folder | Project |
|------|--------|----------|:---:|:---:|:---:|
| Compute Instance | `compute/gcp_vm` | `google_compute_instance` | ➖ | ➖ | ✅ |
| Instance Template | `compute/gcp_vm` | `google_compute_instance_template` | ➖ | ➖ | ✅ |
| GKE Cluster | `compute/gcp_gke` | `google_container_cluster` | ➖ | ➖ | ✅ |
| GKE Node Pool | `compute/gcp_gke` | `google_container_node_pool` | ➖ | ➖ | ✅ |
| Cloud Run Service | `compute/gcp_cloud_run` | `google_cloud_run_v2_service` | ➖ | ➖ | ✅ |
| App Engine Application | `compute/gcp_app_engine` | `google_app_engine_application` | ➖ | ➖ | ✅ |
| Batch Job | `compute/gcp_batch` | `google_batch_job` | ➖ | ➖ | ✅ |

---

## Scope Summary

| Scope | Resources anchored here |
|-------|------------------------|
| **Organization** | Cloud Identity Groups & Memberships, Org IAM bindings, Org policies, Folder/Project parent (when org-rooted) |
| **Folder** | Folder IAM bindings, Folder IAM members; folders themselves can be nested under an org or another folder |
| **Project** | All compute, networking, storage, and most security resources — the vast majority of GCP APIs are project-scoped |

---

## Notes

- **Cloud Identity Groups** (`gcp_group`) are the only module in this repository that is **organization-scoped with no project dependency**. They require a `customer_id` (the directory customer ID of the Cloud Identity / Workspace tenant) and are global — no region or project ID is needed.
- **Org-policy resources** (`google_organization_policy`, `google_folder_organization_policy`, `google_project_organization_policy`) can be applied at all three levels; the binding resource name changes per level.
- **Essential Contacts** (`gcp_advisory_notification`) can be attached at organization, folder, or project level — the `parent` field determines the scope.
- **IAM** (`gcp_iam`) can be expressed at any level. This repository's `gcp_iam` module targets the project level; org-level and folder-level bindings are managed by the `hierarchy/organization` and `hierarchy/folder` modules respectively.
