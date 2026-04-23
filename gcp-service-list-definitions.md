# Google Cloud Service List — Definitions

Comprehensive list of major Google Cloud services, grouped by category, with short definitions.

> Note: Google Cloud evolves quickly. This list focuses on broadly used and generally available services.

> Service hierarchy view: [GCP Module & Service Hierarchy](gcp-module-service-list.md)

---

## Compute

| Service | Definition |
|---------|------------|
| Compute Engine | Infrastructure-as-a-Service (IaaS) virtual machines with full control over machine type, OS, disks, and networking. |
| Autoscaling (MIG) | Managed Instance Group autoscaler that automatically scales the number of VMs based on CPU utilization, HTTP LB utilization, custom Cloud Monitoring metrics, Pub/Sub queue depth, or cron-based schedules — **[Explainer](modules/networking/gcp_autoscaling/gcp_autoscaling.md)** · **[Module](modules/networking/gcp_autoscaling/README.md)** |
| Google Kubernetes Engine (GKE) | Managed Kubernetes service for deploying, scaling, and operating containerized workloads. |
| Cloud Run | Fully managed serverless platform for stateless HTTP containers with automatic scaling to zero. |
| App Engine | Platform-as-a-Service (PaaS) for deploying web apps and APIs in standard or flexible runtimes. |
| Batch | Managed service for scheduling and running large-scale batch jobs on Google Cloud compute resources. |
| Spot VMs | Deeply discounted Compute Engine capacity for fault-tolerant workloads with possible preemption. |
| Bare Metal Solution | Dedicated bare metal infrastructure for specialized workloads and strict compatibility needs. |

---

## Storage

| Service | Definition |
|---------|------------|
| Cloud Storage | Object storage for unstructured data with Standard, Nearline, Coldline, and Archive classes. — **[Module](modules/storage/gcp_cloud_storage/README.md)** |
| Filestore | Managed NFS file storage for applications requiring shared POSIX-compatible file systems. |
| Persistent Disk | Durable block storage for Compute Engine and GKE workloads. |
| Hyperdisk | High-performance, scalable block storage family for demanding IOPS and throughput requirements. |
| Local SSD | High-throughput, low-latency ephemeral local block storage attached directly to VM hosts. |
| Backup and DR Service | Managed backup, restore, and disaster recovery orchestration for cloud and hybrid workloads. |

---

## Databases

| Service | Definition |
|---------|------------|
| Cloud SQL | Fully managed relational database service for MySQL, PostgreSQL, and SQL Server. — **[Module](modules/database/gcp_cloud_sql/README.md)** |
| AlloyDB for PostgreSQL | High-performance PostgreSQL-compatible managed database for transactional workloads. |
| Cloud Spanner | Globally distributed, strongly consistent relational database with horizontal scalability. |
| Firestore | Serverless NoSQL document database for mobile, web, and backend app development. |
| Bigtable | Petabyte-scale, low-latency NoSQL wide-column database for analytical and operational workloads. |
| Memorystore | Managed in-memory data store for Redis and Memcached caching workloads. |
| Datastream | Serverless change data capture (CDC) and replication service for database migration and analytics. |
| Database Migration Service | Managed service for migrating MySQL/PostgreSQL/SQL Server databases to Google Cloud. |

---

## Analytics & Data Engineering

| Service | Definition |
|---------|------------|
| BigQuery | Serverless enterprise data warehouse for SQL analytics at scale. |
| BigQuery Omni | Extends BigQuery query and governance capabilities across AWS and Azure data. |
| Dataflow | Fully managed Apache Beam service for stream and batch data processing pipelines. |
| Dataproc | Managed Spark/Hadoop ecosystem service for large-scale data processing jobs. |
| Pub/Sub | Global messaging and event ingestion service for asynchronous and streaming architectures. |
| Data Fusion | Managed, visual data integration service for building ETL/ELT pipelines. |
| Dataplex | Unified data management, governance, and quality platform for distributed data estates. |
| Dataform | SQL-based data transformation and orchestration service for analytics engineering in BigQuery. |
| Dataprep (Trifacta) | Visual data preparation service for profiling, cleansing, and transformation tasks. |
| Composer | Managed Apache Airflow service for workflow orchestration and scheduling. |

---

## AI & Machine Learning

| Service | Definition |
|---------|------------|
| Vertex AI | Unified ML platform for building, training, deploying, and monitoring ML models. |
| Vertex AI Pipelines | Managed MLOps workflow orchestration for repeatable ML lifecycle automation. |
| Vertex AI Feature Store | Centralized managed store for serving and managing ML features. |
| Vertex AI Model Garden | Catalog of Google and partner foundation/open models for generative AI use cases. |
| Vertex AI Agent Builder | Toolkit for building enterprise-grade AI agents and retrieval-augmented systems. |
| Generative AI Studio | Vertex AI interface for prompting, tuning, and evaluating generative models. |
| Document AI | AI-powered document extraction and understanding service for structured outputs. |
| Vision AI / Vision API | Computer vision services for image analysis, OCR, labeling, and detection use cases. |
| Speech-to-Text | Automatic speech recognition for transcribing audio to text. |
| Text-to-Speech | Neural speech synthesis that converts text into natural-sounding spoken audio. |
| Translation API | Neural machine translation service for multilingual application and content workflows. |
| Natural Language API | NLP service for sentiment, entity extraction, classification, and syntax analysis. |

---

## Networking

| Service | Definition |
|---------|------------|
| Virtual Private Cloud (VPC) | Global virtual networking service with subnets, routing, firewalling, and connectivity controls. — **[Module](modules/networking/gcp_networks/README.md)** |
| Cloud Load Balancing | Global and regional managed load balancing across HTTP(S), TCP/UDP, and internal/external traffic. |
| Cloud CDN | Content delivery network integrated with Google edge locations for low-latency delivery. |
| Cloud DNS | Managed authoritative DNS hosting with global anycast and high availability. |
| VPC Subnets | Regional IP ranges inside a VPC network that segment workloads and define where private resources are placed. |
| Cloud NAT | Managed network address translation for private instances needing outbound internet access. — **[Module](modules/networking/gcp_cloud_nat/README.md)** |
| Cloud Router | Dynamic routing service for hybrid connectivity using BGP. — **[Module](modules/networking/gcp_cloud_router/README.md)** |
| Cloud Interconnect | Dedicated or partner connectivity between on-premises networks and Google Cloud. |
| Cloud VPN | Encrypted IPSec VPN tunnels for secure hybrid or multi-cloud networking. — **[Explainer](modules/networking/gcp_cloud_vpn/gcp-cloud-vpn.md)** · **[Module](modules/networking/gcp_cloud_vpn/README.md)** |
| Network Connectivity Center | Centralized hub-and-spoke management for enterprise hybrid and multi-cloud connectivity. |
| Traffic Director | Managed service mesh traffic control plane for advanced service networking. |

---

## Security & Identity

| Service | Definition |
|---------|------------|
| Identity and Access Management (IAM) | Fine-grained access control for users, groups, service accounts, and resources. — **[Module](modules/security/gcp_iam/README.md)** |
| Cloud Identity | Identity, endpoint, and access management platform for workforce and device governance. — **[Explainer](modules/security/gcp_group/gcp-group.md)** · **[Module](modules/security/gcp_group/README.md)** |
| Secret Manager | Managed service for storing, rotating, and accessing secrets securely. — **[Explainer](modules/security/gcp_secret_manager/gcp-secret-manager.md)** |
| Cloud Key Management Service (KMS) | Managed encryption key lifecycle service using software or HSM-backed keys. — **[Explainer](modules/security/gcp_cloud_kms/gcp-cloud-kms.md)** |
| Cloud HSM | Hardware security modules for dedicated cryptographic key operations. |
| Certificate Authority Service | Managed private PKI for issuing and managing X.509 certificates. — **[Explainer](modules/security/gcp_certificate_authority/gcp-certificate-authority.md)** |
| Certificate Manager | Managed TLS/SSL certificate provisioning, renewal, and map-based assignment service for Google Cloud load balancers. — **[Explainer](modules/security/gcp_certificate_manager/gcp-certificate-manager.md)** |
| Advisory Notifications | Managed service that delivers security, privacy, and compliance notifications from Google to organization administrators via subscriptions and Essential Contacts. — **[Explainer](modules/security/gcp_advisory_notification/gcp-advisory-notification.md)** |
| Security Command Center | Security posture and threat management platform for Google Cloud resources. |
| Cloud Armor | DDoS protection and web application firewall (WAF) service. |
| reCAPTCHA Enterprise | Fraud and abuse protection for web and mobile applications. |
| BeyondCorp Enterprise | Zero-trust access platform for secure access to applications and resources. |
| VPC Service Controls | Security perimeter controls to reduce data exfiltration risk across managed services. |

---

## Management, Monitoring & DevOps

| Service | Definition |
|---------|------------|
| Cloud Monitoring | Metrics, dashboards, uptime checks, and alerting for infrastructure and applications. — **[Explainer](modules/monitoring_devops/gcp_cloud_monitoring/gcp-cloud-monitoring.md)** · **[Module](modules/monitoring_devops/gcp_cloud_monitoring/README.md)** |
| Cloud Logging | Centralized log collection, routing, analysis, and export service. — **[Explainer](modules/monitoring_devops/gcp_cloud_logging/gcp-cloud-logging.md)** · **[Module](modules/monitoring_devops/gcp_cloud_logging/README.md)** |
| Cloud Trace | Distributed tracing service for latency analysis and performance diagnostics. |
| Cloud Profiler | Continuous production profiling for CPU and memory optimization. |
| Error Reporting | Automatic grouping and alerting for runtime application errors. |
| Cloud Audit Logs | Immutable audit logs for admin, data access, and system events. |
| Cloud Build | Managed CI/CD build service for container and application artifact pipelines. |
| Artifact Registry | Secure repository for container images and language packages. |
| Cloud Deploy | Managed continuous delivery service for GKE, Cloud Run, and Anthos targets. |
| Source Repositories | Hosted private Git repositories integrated with Google Cloud IAM and tooling. |
| Infrastructure Manager | Managed Terraform-based infrastructure orchestration and state operations. |

---

## Integration & APIs

| Service | Definition |
|---------|------------|
| API Gateway | Managed API front door for serverless and microservice backends. |
| Apigee | Full API management platform for design, security, analytics, monetization, and lifecycle governance. |
| Eventarc | Event routing service for connecting Google Cloud events to Cloud Run, Workflows, and GKE targets. |
| Workflows | Managed orchestration service for sequencing Google Cloud and HTTP-based APIs. |
| Cloud Tasks | Managed asynchronous task queue for reliable deferred execution. |
| Cloud Scheduler | Fully managed cron service for scheduled jobs and HTTP/Pub/Sub targets. |
| Service Directory | Managed service registry for discovering service endpoints across environments. |

---

## End-User & Business Applications

| Service | Definition |
|---------|------------|
| Looker | Modern BI and semantic modeling platform for governed analytics and dashboards. |
| Looker Studio | Self-service dashboarding and reporting tool for visual analytics and sharing. |
| Contact Center AI Platform (CCAI) | AI-assisted contact center capabilities for conversational experiences and agent support. |
| Google Maps Platform | Location services APIs and SDKs for maps, routes, geocoding, and places intelligence. |

---

## Hybrid & Multi-Cloud

| Service | Definition |
|---------|------------|
| Anthos | Platform for managing Kubernetes and cloud-native workloads across hybrid and multi-cloud environments. |
| Google Distributed Cloud | Managed solutions for running Google Cloud services in edge and disconnected environments. |
| Migrate to Virtual Machines | Service for migrating VM workloads from on-premises and other clouds to Compute Engine. |

---

## Cost Management & Governance

| Service | Definition |
|---------|------------|
| Cloud Resource Manager (Organization/Folders/Projects) | Hierarchy and policy control plane for organizing cloud resources and delegating governance boundaries. — **[Explainer](modules/governance/gcp-resource_manager/gcp-resource-manager.md)** |
| Cloud Billing | Centralized billing account and invoicing framework for all Google Cloud usage. — **[Explainer](modules/governance/gcp_billing/gcp-billing.md)** |
| Cloud Quotas | System-enforced resource limits per project/region with self-service adjustment requests. — **[Explainer](modules/governance/gcp_quotas/gcp-quotas.md)** |
| Labels | Key-value metadata for cost attribution, filtering, and automation targeting across GCP resources. — **[Explainer](modules/governance/gcp_labels/gcp-labels.md)** |
| Billing Budgets & Alerts | Budget threshold monitoring and alerting to control spend. |
| Cost Table / Billing Export | Detailed cost and usage export to BigQuery for analysis and reporting. |
| FinOps Hub | Cost optimization insights and recommendations for cloud financial management. |
| Recommender | Optimization recommendations for idle resources, rightsizing, and savings opportunities. |

---

## Related Docs

- [GCP Module & Service Hierarchy](gcp-module-service-list.md)
- [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md)
- [GCP Organization Module](modules/governance/organization/README.md)
- [GCP Folder Module](modules/governance/folder/README.md)
- [GCP Project Module](modules/governance/project/README.md)
- [GCP Subnetworks Module](modules/networking/gcp_subnetworks/README.md)
- [GCP Networks (VPC) Module](modules/networking/gcp_networks/README.md)
- [GCP Cloud NAT Module](modules/networking/gcp_cloud_nat/README.md)
- [GCP Cloud Router Module](modules/networking/gcp_cloud_router/README.md)
- [GCP Cloud VPN Module](modules/networking/gcp_cloud_vpn/README.md)
- [GCP Cloud VPN Deployment Plan](tf-plans/gcp_cloud_vpn/README.md)
- [GCP IAM Module](modules/security/gcp_iam/README.md)
- [GCP IAM Deployment Plan](tf-plans/gcp_iam/README.md)
- [GCP Cloud SQL Module](modules/database/gcp_cloud_sql/README.md)
- [GCP Cloud SQL Deployment Plan](tf-plans/gcp_cloud_sql/README.md)
- [Database Service Explainers](modules/database/)
- [Governance Service Explainers](modules/governance/)
- [Monitoring & DevOps Service Explainers](modules/monitoring_devops/)
- [Cloud Monitoring Explainer](modules/monitoring_devops/gcp_cloud_monitoring/gcp-cloud-monitoring.md)
- [Cloud Logging Explainer](modules/monitoring_devops/gcp_cloud_logging/gcp-cloud-logging.md)
- [Cloud Build Explainer](modules/monitoring_devops/gcp_cloud_build/gcp-cloud-build.md)
- [Artifact Registry Explainer](modules/monitoring_devops/gcp_artifact_registry/gcp-artifact-registry.md)
- [Cloud Deploy Explainer](modules/monitoring_devops/gcp_cloud_deploy/gcp-cloud-deploy.md)
- [Infrastructure Manager Explainer](modules/monitoring_devops/gcp_infrastructure_manager/gcp-infrastructure-manager.md)
- [Resource Manager Explainer](modules/governance/gcp-resource_manager/gcp-resource-manager.md)
- [Cloud Billing Explainer](modules/governance/gcp_billing/gcp-billing.md)
- [Cloud Quotas Explainer](modules/governance/gcp_quotas/gcp-quotas.md)
- [Labels Explainer](modules/governance/gcp_labels/gcp-labels.md)
- [GCP Cloud Storage Module](modules/storage/gcp_cloud_storage/README.md)
- [GCP Cloud Storage Deployment Plan](tf-plans/gcp_cloud_storage/README.md)
- [GCP Cloud Identity Groups Module](modules/security/gcp_group/README.md)
- [GCP Cloud Identity Groups Deployment Plan](tf-plans/gcp_group/README.md)
- [Compute Service Explainers](modules/compute/)
- [Storage Service Explainers](modules/storage/)
- [Networking Service Explainers](modules/networking/)
- [Security Service Explainers](modules/security/)
- [Release Notes](RELEASE.md)
