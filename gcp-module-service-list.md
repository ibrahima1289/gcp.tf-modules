# GCP Module & Service Hierarchy

Hierarchical view of Google Cloud service domains used in this repository documentation.

> Back to [README](README.md)

---

## Coverage Summary

| Metric | Count |
|--------|-------|
| **Service Domains** | **12** |
| **Services Listed** | **95** |
| **Resource Hierarchy Levels** | **4** |
| **Terraform Modules in repo** | **11** — [Organization](modules/governance/organization/README.md), [Folder](modules/governance/folder/README.md), [Project](modules/governance/project/README.md), [Subnetworks](modules/networking/gcp_subnetworks/README.md), [Networks (VPC)](modules/networking/gcp_networks/README.md), [Cloud NAT](modules/networking/gcp_cloud_nat/README.md), [Cloud Router](modules/networking/gcp_cloud_router/README.md), [IAM](modules/security/gcp_iam/README.md), [Cloud Storage](modules/storage/gcp_cloud_storage/README.md), [Cloud Identity Groups](modules/security/gcp_group/README.md), [Cloud SQL](modules/database/gcp_cloud_sql/README.md) |
| **Service Explainer docs in modules** | **36** — [Hierarchy](modules/governance/), [Compute](modules/compute/), [Storage](modules/storage/), [Networking](modules/networking/), [Security](modules/security/), [Database](modules/database/), [Governance](modules/governance/) |

---

## Google Cloud Resource Hierarchy (Organization → Folder → Project → Resources)

```text
Organization
└── Folder(s)
  └── Project(s)
    └── Resources
      ├── Compute Engine VM instances
      ├── GKE clusters
      ├── Cloud Storage buckets
      ├── Cloud SQL instances
      ├── BigQuery datasets/tables
      ├── Pub/Sub topics/subscriptions
      ├── VPC networks/subnets/firewall rules
      └── IAM policies/service accounts
```

### Hierarchy Levels

> **Legend:** ✅ Full Terraform support · ⚠️ Partial/limited support · ❌ No Terraform resource (API/console only)

| Level | Purpose | Notes | Terraform | Terraform Resource |
|-------|---------|-------|:---------:|--------------------|
| **Organization** | Top-most node representing a company/domain tenant in Google Cloud. | Central point for org-wide policies, IAM, and governance. Org node itself is created outside Terraform via Google Workspace/Cloud Identity. | ⚠️ | [`google_organization_iam_member`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam) · [`google_org_policy_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) · [`google_logging_organization_sink`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) · [`google_essential_contacts_contact`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/essential_contacts_contact) — **[Module](modules/governance/organization/README.md)** |
| **Folder** | Logical grouping for projects (e.g., by environment, business unit, or team). | Can be nested for delegated administration and policy boundaries. | ✅ | [`google_folder`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder) · [`google_folder_iam_member`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_iam) · [`google_org_policy_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) · [`google_logging_folder_sink`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_sink) · [`google_essential_contacts_contact`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/essential_contacts_contact) — **[Module](modules/governance/folder/README.md)** |
| **Project** | Primary isolation boundary for APIs, billing, quotas, and IAM bindings. | All deployable resources live inside a project. | ✅ | [`google_project`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project) · [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) — **[Module](modules/governance/project/README.md)** |
| **Resources** | Actual cloud services (VMs, buckets, databases, load balancers, etc.). | Inherit policies from Organization → Folder → Project unless overridden. | ✅ | See [Service Hierarchy](#service-hierarchy-domain--services) tables below |

### Inheritance Model

- IAM and Organization Policy constraints are inherited down the tree.
- Effective permissions at resource level are the combination of inherited + directly assigned policies.
- Billing is linked at project level, while governance is typically enforced from organization/folder levels.

---

## Service Hierarchy (Domain → Services)

> **Legend:** ✅ Full Terraform support · ⚠️ Partial/limited support · ❌ No Terraform resource (API/console only)

### Compute

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Compute Engine | ✅ | [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) |
| Google Kubernetes Engine (GKE) | ✅ | [`google_container_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) |
| Cloud Run | ✅ | [`google_cloud_run_v2_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) |
| App Engine | ✅ | [`google_app_engine_application`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application) |
| Batch | ✅ | [`google_batch_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/batch_job) |
| Spot VMs | ✅ | Via `scheduling` block in `google_compute_instance` |
| Bare Metal Solution | ❌ | Provisioned via Google Sales; no Terraform resource |

### Storage

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Cloud Storage | ✅ | [`google_storage_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) — **[Module](modules/storage/gcp_cloud_storage/README.md)** |
| Filestore | ✅ | [`google_filestore_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_instance) |
| Persistent Disk | ✅ | [`google_compute_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) |
| Hyperdisk | ✅ | [`google_compute_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) (type = `hyperdisk-*`) |
| Local SSD | ✅ | Via `scratch_disk` block in `google_compute_instance` |
| Backup and DR Service | ⚠️ | [`google_backup_dr_management_server`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/backup_dr_management_server) (limited) |

### Databases

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Cloud SQL | ✅ | [`google_sql_database_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) · [`google_sql_database`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) · [`google_sql_user`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) — **[Module](modules/database/gcp_cloud_sql/README.md)** |
| AlloyDB for PostgreSQL | ✅ | [`google_alloydb_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_cluster) |
| Cloud Spanner | ✅ | [`google_spanner_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_instance) |
| Firestore | ✅ | [`google_firestore_database`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database) |
| Bigtable | ✅ | [`google_bigtable_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigtable_instance) |
| Memorystore | ✅ | [`google_redis_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance) / [`google_memcache_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/memcache_instance) |
| Datastream | ✅ | [`google_datastream_stream`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/datastream_stream) |
| Database Migration Service | ✅ | [`google_database_migration_service_migration_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/database_migration_service_migration_job) |

### Analytics & Data Engineering

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| BigQuery | ✅ | [`google_bigquery_dataset`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) / [`google_bigquery_table`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) |
| BigQuery Omni | ⚠️ | Via `google_bigquery_connection` (external data source) |
| Dataflow | ✅ | [`google_dataflow_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataflow_job) |
| Dataproc | ✅ | [`google_dataproc_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_cluster) |
| Pub/Sub | ✅ | [`google_pubsub_topic`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) / [`google_pubsub_subscription`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) |
| Data Fusion | ✅ | [`google_data_fusion_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/data_fusion_instance) |
| Dataplex | ✅ | [`google_dataplex_lake`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataplex_lake) |
| Dataform | ✅ | [`google_dataform_repository`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataform_repository) |
| Dataprep (Trifacta) | ❌ | SaaS UI tool; no Terraform resource |
| Composer | ✅ | [`google_composer_environment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/composer_environment) |

### AI & Machine Learning

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Vertex AI | ✅ | [`google_vertex_ai_endpoint`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_endpoint) / [`google_vertex_ai_dataset`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_dataset) |
| Vertex AI Pipelines | ⚠️ | [`google_vertex_ai_pipeline_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_pipeline_job) (limited; typically invoked via SDK) |
| Vertex AI Feature Store | ✅ | [`google_vertex_ai_feature_store`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_feature_store) |
| Vertex AI Model Garden | ❌ | API/console based; no direct Terraform resource |
| Vertex AI Agent Builder | ✅ | [`google_discovery_engine_data_store`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/discovery_engine_data_store) |
| Generative AI Studio | ❌ | Console/API/SDK based; no Terraform resource |
| Document AI | ✅ | [`google_document_ai_processor`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/document_ai_processor) |
| Vision AI / Vision API | ❌ | API consumed in code; enable via `google_project_service` |
| Speech-to-Text | ❌ | API consumed in code; enable via `google_project_service` |
| Text-to-Speech | ❌ | API consumed in code; enable via `google_project_service` |
| Translation API | ❌ | API consumed in code; enable via `google_project_service` |
| Natural Language API | ❌ | API consumed in code; enable via `google_project_service` |

### Networking

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Virtual Private Cloud (VPC) | ✅ | [`google_compute_network`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) · [`google_compute_shared_vpc_host_project`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_shared_vpc_host_project) — **[Module](modules/networking/gcp_networks/README.md)** |
| VPC Subnets | ✅ | [`google_compute_subnetwork`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) — **[Module](modules/networking/gcp_subnetworks/README.md)** |
| Cloud Load Balancing | ✅ | [`google_compute_backend_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) / [`google_compute_url_map`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) |
| Cloud CDN | ✅ | Via `enable_cdn` on `google_compute_backend_bucket` / `google_compute_backend_service` |
| Cloud DNS | ✅ | [`google_dns_managed_zone`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) / [`google_dns_record_set`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) |
| Cloud NAT | ✅ | [`google_compute_router_nat`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) · [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) — **[Module](modules/networking/gcp_cloud_nat/README.md)** |
| Cloud Router | ✅ | [`google_compute_router`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) · [`google_compute_router_interface`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) · [`google_compute_router_peer`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) — **[Module](modules/networking/gcp_cloud_router/README.md)** |
| Cloud Interconnect | ✅ | [`google_compute_interconnect_attachment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_interconnect_attachment) |
| Cloud VPN | ✅ | [`google_compute_vpn_tunnel`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel) / [`google_compute_ha_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway) |
| Network Connectivity Center | ✅ | [`google_network_connectivity_hub`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_hub) |
| Traffic Director | ✅ | Via `google_compute_backend_service` with Traffic Director config |

### Security & Identity

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Identity and Access Management (IAM) | ✅ | [`google_project_iam_binding`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam) / [`google_service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) · [`google_project_iam_custom_role`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_custom_role) — **[Module](modules/security/gcp_iam/README.md)** |
| Cloud Identity Groups | ✅ | [`google_cloud_identity_group`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) · [`google_cloud_identity_group_membership`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) — **[Module](modules/security/gcp_group/README.md)** |
| Secret Manager | ✅ | [`google_secret_manager_secret`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) — **[Explainer](modules/security/gcp_secret_manager/gcp-secret-manager.md)** |
| Cloud KMS | ✅ | [`google_kms_key_ring`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) / [`google_kms_crypto_key`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) — **[Explainer](modules/security/gcp_cloud_kms/gcp-cloud-kms.md)** |
| Cloud HSM | ✅ | Via `protection_level = "HSM"` on `google_kms_crypto_key` |
| Certificate Authority Service | ✅ | [`google_privateca_certificate_authority`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privateca_certificate_authority) — **[Explainer](modules/security/gcp_certificate_authority/gcp-certificate-authority.md)** |
| Certificate Manager | ✅ | [`google_certificate_manager_certificate`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate) · [`google_certificate_manager_certificate_map`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate_map) — **[Explainer](modules/security/gcp_certificate_manager/gcp-certificate-manager.md)** |
| Security Command Center | ⚠️ | [`google_scc_notification_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/scc_notification_config) (limited) |
| Cloud Armor | ✅ | [`google_compute_security_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_security_policy) |
| reCAPTCHA Enterprise | ✅ | [`google_recaptcha_enterprise_key`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/recaptcha_enterprise_key) |
| BeyondCorp Enterprise | ✅ | [`google_beyondcorp_app_connection`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/beyondcorp_app_connection) |
| VPC Service Controls | ✅ | [`google_access_context_manager_service_perimeter`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter) |
| Advisory Notifications | ✅ | [`google_advisory_notifications_settings`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/advisory_notifications_settings) — **[Explainer](modules/security/gcp_advisory_notification/gcp-advisory-notification.md)** |

### Management, Monitoring & DevOps

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Cloud Monitoring | ✅ | [`google_monitoring_alert_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) / [`google_monitoring_dashboard`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard) |
| Cloud Logging | ✅ | [`google_logging_sink`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) / [`google_logging_bucket_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_bucket_config) |
| Cloud Trace | ⚠️ | Enable via `google_project_service`; no dedicated config resource |
| Cloud Profiler | ⚠️ | Enable via `google_project_service`; no dedicated config resource |
| Error Reporting | ⚠️ | Enable via `google_project_service`; no dedicated config resource |
| Cloud Audit Logs | ✅ | [`google_folder_iam_audit_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_iam#google_folder_iam_audit_config) |
| Cloud Build | ✅ | [`google_cloudbuild_trigger`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger) |
| Artifact Registry | ✅ | [`google_artifact_registry_repository`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) |
| Cloud Deploy | ✅ | [`google_clouddeploy_delivery_pipeline`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_delivery_pipeline) |
| Source Repositories | ✅ | [`google_sourcerepo_repository`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sourcerepo_repository) |
| Infrastructure Manager | ✅ | [`google_infra_manager_deployment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/infra_manager_deployment) |

### Integration & APIs

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| API Gateway | ✅ | [`google_api_gateway_api`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/api_gateway_api) / [`google_api_gateway_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/api_gateway_gateway) |
| Apigee | ✅ | [`google_apigee_organization`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_organization) / [`google_apigee_environment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_environment) |
| Eventarc | ✅ | [`google_eventarc_trigger`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger) |
| Workflows | ✅ | [`google_workflows_workflow`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workflows_workflow) |
| Cloud Tasks | ✅ | [`google_cloud_tasks_queue`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_tasks_queue) |
| Cloud Scheduler | ✅ | [`google_cloud_scheduler_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_scheduler_job) |
| Service Directory | ✅ | [`google_service_directory_namespace`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_directory_namespace) |

### End-User & Business Applications

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Looker | ✅ | [`google_looker_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/looker_instance) |
| Looker Studio | ❌ | Web-based reporting UI; no Terraform resource |
| Contact Center AI Platform (CCAI) | ❌ | Managed via Dialogflow and CCAI Insights APIs; no single TF resource |
| Google Maps Platform | ❌ | Enable API via `google_project_service`; SDKs consumed in application code |

### Hybrid & Multi-Cloud

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Anthos | ✅ | [`google_gke_hub_membership`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_membership) / [`google_gke_hub_feature`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature) |
| Google Distributed Cloud | ⚠️ | Limited; some resources via `google_edge_container_cluster` |
| Migrate to Virtual Machines | ✅ | [`google_vmmigration_source`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vmmigration_source) |

### Cost Management & Governance

| Service | Terraform | Terraform Resource |
|---------|:---------:|--------------------|
| Cloud Resource Manager | ✅ | [`google_folder`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder) · [`google_project`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project) · [`google_org_policy_policy`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) — **[Explainer](modules/governance/gcp-resource_manager/gcp-resource-manager.md)** |
| Cloud Billing | ✅ | [`google_billing_budget`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) · [`google_billing_project_info`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_project_info) — **[Explainer](modules/governance/gcp_billing/gcp-billing.md)** |
| Billing Budgets & Alerts | ✅ | [`google_billing_budget`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) |
| Cloud Quotas | ✅ | [`google_cloud_quotas_quota_preference`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_quotas_quota_preference) — **[Explainer](modules/governance/gcp_quotas/gcp-quotas.md)** |
| Labels | ✅ | `labels` argument on most resources · [`google_org_policy_custom_constraint`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_custom_constraint) — **[Explainer](modules/governance/gcp_labels/gcp-labels.md)** |
| Cost Table / Billing Export | ⚠️ | Via `google_logging_billing_account_sink` / BigQuery export config |
| FinOps Hub | ❌ | Console/API only; no Terraform resource |
| Recommender | ❌ | Read-only advisory service; no Terraform resource |

---

## Related Docs

- [Google Cloud Service List — Definitions](gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md)
- [GCP Organization Module](modules/governance/organization/README.md)
- [GCP Folder Module](modules/governance/folder/README.md)
- [GCP Project Module](modules/governance/project/README.md)
- [GCP Subnetworks Module](modules/networking/gcp_subnetworks/README.md)
- [GCP Networks (VPC) Module](modules/networking/gcp_networks/README.md)
- [GCP Cloud NAT Module](modules/networking/gcp_cloud_nat/README.md)
- [GCP Cloud Router Module](modules/networking/gcp_cloud_router/README.md)
- [GCP IAM Module](modules/security/gcp_iam/README.md)
- [GCP IAM Deployment Plan](tf-plans/gcp_iam/README.md)
- [GCP Cloud Storage Module](modules/storage/gcp_cloud_storage/README.md)
- [GCP Cloud Storage Deployment Plan](tf-plans/gcp_cloud_storage/README.md)
- [GCP Cloud Identity Groups Module](modules/security/gcp_group/README.md)
- [GCP Cloud Identity Groups Deployment Plan](tf-plans/gcp_group/README.md)
- [Cloud Identity Groups Explainer](modules/security/gcp_group/gcp-group.md)
- [Secret Manager Explainer](modules/security/gcp_secret_manager/gcp-secret-manager.md)
- [Cloud KMS Explainer](modules/security/gcp_cloud_kms/gcp-cloud-kms.md)
- [Certificate Authority Service Explainer](modules/security/gcp_certificate_authority/gcp-certificate-authority.md)
- [Certificate Manager Explainer](modules/security/gcp_certificate_manager/gcp-certificate-manager.md)
- [Advisory Notifications Explainer](modules/security/gcp_advisory_notification/gcp-advisory-notification.md)
- [Compute Service Explainers](modules/compute/)
- [Storage Service Explainers](modules/storage/)
- [Networking Service Explainers](modules/networking/)
- [Security Service Explainers](modules/security/)
- [Database Service Explainers](modules/database/)
- [Governance Service Explainers](modules/governance/)
- [Resource Manager Explainer](modules/governance/gcp-resource_manager/gcp-resource-manager.md)
- [Cloud Billing Explainer](modules/governance/gcp_billing/gcp-billing.md)
- [Cloud Quotas Explainer](modules/governance/gcp_quotas/gcp-quotas.md)
- [Labels Explainer](modules/governance/gcp_labels/gcp-labels.md)
- [Release Notes](RELEASE.md)
