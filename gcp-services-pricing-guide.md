# Google Cloud Services Pricing Guide

A practical pricing reference for major Google Cloud services, including pricing models, common cost drivers, and quick examples.

> Pricing is region-dependent and changes over time. Always validate with the official calculator and product pricing pages.

> Related: [GCP Module & Service Hierarchy](gcp-module-service-list.md) · [Google Cloud Service List — Definitions](gcp-service-list-definitions.md)

## Legend

| Label | Cost Range | Description |
|-------|------------|-------------|
| 🟢 | **FREE / very low** | No direct service fee or typically minimal spend at small scale |
| 🟡 | **$0 - $100+/month** | Moderate costs for development and small-to-medium production usage |
| 🔴 | **$100+/month to high scale** | Can become expensive quickly with throughput, storage, or enterprise scale |

---

## Compute Services

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟡 **Compute Engine** | Per vCPU-second + memory + disk + network egress | e2-medium running 24/7 + boot disk often lands in low-to-mid monthly range depending on region | https://cloud.google.com/compute/all-pricing |
| 🔴 **GKE** | Cluster management fee (standard mode) + node costs + egress | Small production cluster + 3 worker nodes commonly exceeds $100/month | https://cloud.google.com/kubernetes-engine/pricing |
| 🟡 **Cloud Run** | Per request + vCPU-second + GiB-second (with free tier) | Low-traffic APIs often stay near free/low cost; sustained traffic scales linearly | https://cloud.google.com/run/pricing |
| 🟡 **App Engine** | Instance hours + requests + outgoing bandwidth (free quotas for standard env) | Low traffic apps can remain low; always-on flexible instances cost more | https://cloud.google.com/appengine/pricing |
| 🟢 **Batch** | No standalone fee; pay for underlying compute/storage/network | Cost equals VM resources used by jobs | https://cloud.google.com/batch/pricing |

---

## Storage Services

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟡 **Cloud Storage** | Per GB-month by class + operations + retrieval + egress | 1 TB Standard storage is moderate monthly cost; Archive is much cheaper for cold data | https://cloud.google.com/storage/pricing |
| 🟡 **Filestore** | Provisioned capacity + performance tier | Enterprise and high-throughput tiers scale quickly in cost | https://cloud.google.com/filestore/pricing |
| 🟡 **Persistent Disk / Hyperdisk** | Per provisioned GB-month + provisioned performance (for some disk types) | SSD and high-IOPS hyperdisk profiles cost more than balanced/standard | https://cloud.google.com/compute/disks-image-pricing |
| 🟡 **Backup and DR** | Protected capacity + snapshots + backup storage + transfer | Cost depends on retention period and backup frequency | https://cloud.google.com/backup-disaster-recovery/pricing |

---

## Database Services

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟡 **Cloud SQL** | Instance vCPU/RAM + storage + backups + network | Dev instances can be low cost; HA production typically exceeds $100/month | https://cloud.google.com/sql/pricing |
| 🔴 **AlloyDB for PostgreSQL** | vCPU/RAM + storage + I/O + backups | Production clusters are usually premium-priced vs basic managed PostgreSQL | https://cloud.google.com/alloydb/pricing |
| 🔴 **Cloud Spanner** | Compute units/nodes + storage + backup + network | Designed for high-scale workloads; minimum reliable setups can be expensive | https://cloud.google.com/spanner/pricing |
| 🟡 **Firestore** | Document reads/writes/deletes + storage + egress | Write-heavy workloads can grow quickly; small apps can remain very low cost | https://cloud.google.com/firestore/pricing |
| 🔴 **Bigtable** | Node/hour (or serverless units) + storage + backup + networking | Always-on production clusters usually exceed $100/month | https://cloud.google.com/bigtable/pricing |
| 🟡 **Memorystore (Redis/Memcached)** | Per node/hour by tier + memory size + network | Basic caching node starts moderate; HA/large memory tiers rise quickly | https://cloud.google.com/memorystore/pricing |

---

## Analytics & Data Engineering

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟡 **BigQuery** | Storage (active/long-term) + query bytes processed (on-demand) or slot reservations | 1 TB queried on-demand is billed per TB; high-query volumes benefit from reservations | https://cloud.google.com/bigquery/pricing |
| 🟡 **Dataflow** | Worker vCPU/memory time + streaming engine + shuffle/storage/network | Continuous streaming jobs can become significant monthly spend | https://cloud.google.com/dataflow/pricing |
| 🟡 **Dataproc** | VM costs + Dataproc management surcharge + storage/network | Ephemeral clusters are cost-efficient; long-running clusters accumulate cost quickly | https://cloud.google.com/dataproc/pricing |
| 🟡 **Pub/Sub** | Throughput (GiB) for publish/delivery + retention/storage beyond free usage | Event-heavy systems can scale cost with message volume | https://cloud.google.com/pubsub/pricing |
| 🟡 **Composer** | Environment resources + scheduler/workers + Cloud SQL + storage/network | Managed Airflow environments are typically not low-cost in production | https://cloud.google.com/composer/pricing |
| 🟡 **Dataplex / Data Fusion / Dataform** | Service-specific processing units + storage + orchestration usage | ETL intensity and job runtime are major cost drivers | https://cloud.google.com/products/calculator |

---

## AI & Machine Learning

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🔴 **Vertex AI (Training/Serving)** | Per training node-hour + online endpoint compute + storage | Always-on endpoints and GPU workloads can be high-cost | https://cloud.google.com/vertex-ai/pricing |
| 🔴 **Vertex AI Generative AI** | Per input/output token (model-dependent), tuning and evaluation charges | High-volume prompt traffic can scale rapidly | https://cloud.google.com/vertex-ai/generative-ai/pricing |
| 🟡 **Document AI** | Per processed page/document by processor type | Invoice/contract parsing at scale can become moderate-to-high spend | https://cloud.google.com/document-ai/pricing |
| 🟡 **Vision API** | Per image or feature request with tiered pricing | Large image analysis batches can cross $100/month quickly | https://cloud.google.com/vision/pricing |
| 🟡 **Speech-to-Text** | Per audio minute processed | Contact-center transcription workloads can become expensive at scale | https://cloud.google.com/speech-to-text/pricing |
| 🟡 **Text-to-Speech** | Per character synthesized (voice type dependent) | Premium neural voices cost more than standard voices | https://cloud.google.com/text-to-speech/pricing |
| 🟡 **Translation API** | Per character translated | Multilingual, high-throughput apps can add up fast | https://cloud.google.com/translate/pricing |

---

## Networking Services

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟢 **VPC** | Core VPC constructs are free; pay for dependent resources and egress | Main cost drivers are NAT, load balancers, and data transfer — **[Module](modules/networking/gcp_networks/README.md)** | https://cloud.google.com/vpc/pricing |
| 🟢 **VPC Subnets** | No standalone subnet fee | Subnets themselves are free; costs come from attached resources, Private Google access traffic patterns, and network egress | https://cloud.google.com/vpc/pricing |
| 🟡 **Cloud Load Balancing** | Forwarding rules + data processing + optional features | Public global LB with steady traffic usually incurs recurring monthly cost | https://cloud.google.com/load-balancing/pricing |
| 🟡 **Cloud CDN** | Cache egress + cache fill + HTTP(S) request components | Global content delivery costs correlate with egress volume | https://cloud.google.com/cdn/pricing |
| 🟡 **Cloud NAT** | Gateway uptime + data processed | Frequent outbound internet traffic can materially increase bill | https://cloud.google.com/nat/pricing |
| 🟡 **Cloud Interconnect** | Port capacity (Dedicated) or Partner rates + egress | Enterprise hybrid links are often significant recurring spend | https://cloud.google.com/network-connectivity/docs/interconnect/pricing |
| 🟡 **Cloud VPN** | Tunnel uptime + egress charges | Multiple HA tunnels + heavy traffic increases monthly cost | https://cloud.google.com/network-connectivity/docs/vpn/pricing |
| 🟡 **Cloud DNS** | Managed zones + DNS queries | Usually low cost unless very high DNS query volume | https://cloud.google.com/dns/pricing |

---

## Security, Identity & Governance

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟢 **IAM** | No direct service fee | Access control itself is free | https://cloud.google.com/iam/pricing |
| 🟢 **Organization Policy** | No direct service fee | Constraint enforcement at org/folder/project level is free | https://cloud.google.com/resource-manager/docs/organization-policy/overview |
| 🟢 **Essential Contacts** | No direct service fee | Notification contact registration is free | https://cloud.google.com/resource-manager/docs/managing-notification-contacts |
| 🟢 **Resource Manager (Org/Folder/Project)** | No direct service fee | Managing the hierarchy is free; costs come from resources deployed within projects | https://cloud.google.com/resource-manager/pricing |
| 🟡 **Secret Manager** | Per active secret version + access operations | Large numbers of secrets/reads can become moderate monthly spend | https://cloud.google.com/secret-manager/pricing |
| 🟡 **Cloud KMS / Cloud HSM** | Per key version + cryptographic operations (and HSM premium for HSM-backed keys) | High request rate encryption can grow cost steadily | https://cloud.google.com/kms/pricing |
| 🔴 **Security Command Center (premium tiers)** | Per protected resource / tier-based features | Enterprise-scale orgs can incur substantial security tooling costs | https://cloud.google.com/security-command-center/pricing |
| 🟡 **Cloud Armor** | Policy/rule pricing + request volume + advanced protection options | High request APIs/apps can drive WAF costs noticeably | https://cloud.google.com/armor/pricing |
| 🟡 **reCAPTCHA Enterprise** | Per assessment / challenge volume | Public apps with high traffic can exceed free allocations quickly | https://cloud.google.com/recaptcha-enterprise/pricing |

---

## Observability & DevOps

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟡 **Cloud Monitoring** | Chargeable metrics, API reads, uptime checks beyond free allotments | Custom metrics at scale become a common hidden cost | https://cloud.google.com/stackdriver/pricing |
| 🟡 **Cloud Logging** | Log ingestion + retention/storage + log analytics/querying | High log volume environments can become expensive quickly | https://cloud.google.com/stackdriver/pricing |
| 🟢 **Cloud Trace / Profiler / Error Reporting** | Low-cost or included quotas with potential overage depending on usage | Typically low-to-moderate unless very high cardinality and volume | https://cloud.google.com/stackdriver/pricing |
| 🟡 **Cloud Build** | Build minutes by machine class + artifact storage/network | Frequent CI pipelines can become medium monthly spend | https://cloud.google.com/build/pricing |
| 🟡 **Artifact Registry** | Storage + network egress + vulnerability scanning options | Large container/package repositories accumulate storage cost | https://cloud.google.com/artifact-registry/pricing |
| 🟢 **Cloud Deploy** | No standalone fee; pay for underlying runtime and delivery targets | Cost mostly comes from target environment resources | https://cloud.google.com/deploy/pricing |

---

## Integration & API Management

| Service | Pricing Model | Cost Examples | Pricing Reference |
|---------|---------------|---------------|-------------------|
| 🟡 **API Gateway** | Per API call + data transfer | High call volumes can be significant for public APIs | https://cloud.google.com/api-gateway/pricing |
| 🔴 **Apigee** | Subscription/entitlement model + usage-based components | Enterprise API programs usually represent meaningful platform spend | https://cloud.google.com/apigee/pricing |
| 🟡 **Eventarc** | Event delivery volume + underlying targets | Event-driven architectures scale cost with event throughput | https://cloud.google.com/eventarc/pricing |
| 🟢 **Cloud Scheduler** | Per job/month after small free allotments | Usually very low cost for typical cron workloads | https://cloud.google.com/scheduler/pricing |
| 🟡 **Cloud Tasks** | Per enqueued task operations | High task throughput can cross into moderate monthly spend | https://cloud.google.com/tasks/pricing |
| 🟢 **Workflows** | Per step execution and runtime | Small orchestration use cases are typically low cost | https://cloud.google.com/workflows/pricing |

---

## Cost Optimization Tips

1. Use committed use discounts (CUDs) for steady Compute Engine and GKE workloads.
2. Prefer autoscaling and scale-to-zero platforms (Cloud Run) for variable demand.
3. Partition and cluster BigQuery tables; avoid scanning unnecessary columns.
4. Apply Cloud Storage lifecycle rules (Standard → Nearline/Coldline/Archive).
5. Set budgets, alerts, and anomaly detection in Cloud Billing.
6. Reduce log ingestion noise using exclusions and targeted retention.
7. Minimize inter-region and internet egress where architecture allows.
8. Use Spot VMs for fault-tolerant jobs.

---

## Official Pricing Resources

- Google Cloud Pricing: https://cloud.google.com/pricing
- Google Cloud Pricing Calculator: https://cloud.google.com/products/calculator
- Google Cloud Free Program: https://cloud.google.com/free
- Billing export to BigQuery: https://cloud.google.com/billing/docs/how-to/export-data-bigquery

---

## Related Docs

- [GCP Module & Service Hierarchy](gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](gcp-service-list-definitions.md)
- [GCP Organization Module](modules/hierarchy/organization/README.md)
- [GCP Folder Module](modules/hierarchy/folder/README.md)
- [GCP Project Module](modules/hierarchy/project/README.md)
- [GCP Subnetworks Module](modules/networking/gcp_subnetworks/README.md)
- [GCP Networks (VPC) Module](modules/networking/gcp_networks/README.md)
- [Release Notes](RELEASE.md)
