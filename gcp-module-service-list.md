# GCP Module & Service Hierarchy

Hierarchical view of Google Cloud service domains used in this repository documentation.

> Back to [README](README.md)

---

## Coverage Summary

| Metric | Count |
|--------|-------|
| **Service Domains** | **12** |
| **Services Listed** | **94** |
| **Resource Hierarchy Levels** | **4** |
| **Terraform Modules in repo** | **0 (planned)** |

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

| Level | Purpose | Notes |
|------|---------|-------|
| **Organization** | Top-most node representing a company/domain tenant in Google Cloud. | Central point for org-wide policies, IAM, and governance. |
| **Folder** | Logical grouping for projects (e.g., by environment, business unit, or team). | Can be nested for delegated administration and policy boundaries. |
| **Project** | Primary isolation boundary for APIs, billing, quotas, and IAM bindings. | All deployable resources live inside a project. |
| **Resources** | Actual cloud services (VMs, buckets, databases, load balancers, etc.). | Inherit policies from Organization → Folder → Project unless overridden. |

### Inheritance Model

- IAM and Organization Policy constraints are inherited down the tree.
- Effective permissions at resource level are the combination of inherited + directly assigned policies.
- Billing is linked at project level, while governance is typically enforced from organization/folder levels.

---

## Service Hierarchy (Domain → Services)

- **Compute**
  - Compute Engine
  - Google Kubernetes Engine (GKE)
  - Cloud Run
  - App Engine
  - Batch
  - Spot VMs
  - Bare Metal Solution

- **Storage**
  - Cloud Storage
  - Filestore
  - Persistent Disk
  - Hyperdisk
  - Local SSD
  - Backup and DR Service

- **Databases**
  - Cloud SQL
  - AlloyDB for PostgreSQL
  - Cloud Spanner
  - Firestore
  - Bigtable
  - Memorystore
  - Datastream
  - Database Migration Service

- **Analytics & Data Engineering**
  - BigQuery
  - BigQuery Omni
  - Dataflow
  - Dataproc
  - Pub/Sub
  - Data Fusion
  - Dataplex
  - Dataform
  - Dataprep (Trifacta)
  - Composer

- **AI & Machine Learning**
  - Vertex AI
  - Vertex AI Pipelines
  - Vertex AI Feature Store
  - Vertex AI Model Garden
  - Vertex AI Agent Builder
  - Generative AI Studio
  - Document AI
  - Vision AI / Vision API
  - Speech-to-Text
  - Text-to-Speech
  - Translation API
  - Natural Language API

- **Networking**
  - Virtual Private Cloud (VPC)
  - Cloud Load Balancing
  - Cloud CDN
  - Cloud DNS
  - Cloud NAT
  - Cloud Router
  - Cloud Interconnect
  - Cloud VPN
  - Network Connectivity Center
  - Traffic Director

- **Security & Identity**
  - Identity and Access Management (IAM)
  - Cloud Identity
  - Secret Manager
  - Cloud Key Management Service (KMS)
  - Cloud HSM
  - Certificate Authority Service
  - Security Command Center
  - Cloud Armor
  - reCAPTCHA Enterprise
  - BeyondCorp Enterprise
  - VPC Service Controls

- **Management, Monitoring & DevOps**
  - Cloud Monitoring
  - Cloud Logging
  - Cloud Trace
  - Cloud Profiler
  - Error Reporting
  - Cloud Audit Logs
  - Cloud Build
  - Artifact Registry
  - Cloud Deploy
  - Source Repositories
  - Infrastructure Manager

- **Integration & APIs**
  - API Gateway
  - Apigee
  - Eventarc
  - Workflows
  - Cloud Tasks
  - Cloud Scheduler
  - Service Directory

- **End-User & Business Applications**
  - Looker
  - Looker Studio
  - Contact Center AI Platform (CCAI)
  - Google Maps Platform

- **Hybrid & Multi-Cloud**
  - Anthos
  - Google Distributed Cloud
  - Migrate to Virtual Machines

- **Cost Management & Governance**
  - Cloud Billing
  - Billing Budgets & Alerts
  - Cost Table / Billing Export
  - FinOps Hub
  - Recommender

---

## Related Docs

- [Google Cloud Service List — Definitions](gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md)
- [Release Notes](RELEASE.md)
