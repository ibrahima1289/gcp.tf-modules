# Google Cloud Run

## Service overview

[Google Cloud Run](https://cloud.google.com/run/docs) is a fully managed serverless platform for deploying containerized workloads. Cloud Run automatically provisions and scales the underlying infrastructure — you only pay for the compute used while a request is being handled (or while a job is running). There is no cluster to manage, no node pool to size, and no capacity reservation required.

Cloud Run supports two execution models: **Services** (long-running request handlers) and **Jobs** (finite batch tasks).

---

## How Cloud Run works

You package your code as a container image and push it to Artifact Registry or Container Registry. Cloud Run runs that container in a fully managed environment, handling:

- HTTPS endpoint generation and TLS termination
- Traffic routing and revision management
- Scale-to-zero and scale-out based on concurrency and request rate
- Identity and access through IAM and service accounts

```text
Client Request
      |
Cloud Run Service (HTTPS endpoint, auto-scaled)
  ├── Revision N   (current — 95% traffic)
  └── Revision N-1 (previous — 5% traffic, canary)
      |
Backend APIs / Cloud SQL / Firestore / Pub/Sub
```

---

## Services vs Jobs

| Dimension | Cloud Run Service | Cloud Run Job |
|-----------|-------------------|---------------|
| **Trigger** | HTTP request | Manual, schedule (Cloud Scheduler), or event |
| **Lifecycle** | Runs continuously; scales with traffic | Runs to completion; terminates |
| **Scaling** | Scale to zero ↔ many instances | Parallel task instances, configurable count |
| **Billing** | Per request (CPU allocated during request) | Per CPU-second while running |
| **Typical use** | APIs, webhooks, web apps | ETL, report generation, data migration |
| **Timeout** | Up to 60 minutes per request | Up to 24 hours per task |

---

## Execution environments

| Generation | Description | Default |
|------------|-------------|---------|
| **First generation (gen1)** | Sandbox-based; slower cold starts; no POSIX filesystem | Legacy |
| **Second generation (gen2)** | Full Linux process model; faster cold starts; POSIX filesystem support; better network performance | **Recommended** |

---

## Concurrency and scaling

| Setting | Description |
|---------|-------------|
| **Concurrency** | Max simultaneous requests per container instance (default 80, max 1000) |
| **Min instances** | Minimum number of containers always warm (eliminates cold starts at a cost) |
| **Max instances** | Upper limit on scaling (controls costs and downstream DB connections) |
| **CPU allocation** | "CPU always allocated" — CPU available even between requests (good for background threads) or "CPU only during requests" (default) |
| **Startup CPU boost** | Extra CPU during cold start to reduce startup latency |

---

## Traffic and revision management

| Capability | Description |
|------------|-------------|
| **Revisions** | Each deployment creates a new immutable revision |
| **Traffic splitting** | Route a percentage of traffic to multiple revisions (canary/blue-green) |
| **Tags** | Assign URL tags to specific revisions for testing without routing production traffic |
| **Rollback** | Instantly redirect 100% of traffic to any previous revision |

---

## When to use Cloud Run

- You deploy containerized APIs, webhooks, and background HTTP services.
- Traffic is variable and scale-to-zero saves cost between bursts.
- You want minimal infrastructure management with pay-per-use billing.
- You need simple canary deployments and instant rollbacks.
- Your workload runs in response to Pub/Sub messages, Eventarc triggers, or schedules.

---

## Core capabilities

- Deploy directly from container images in Artifact Registry or Docker Hub.
- Autoscale from zero to high concurrency and back automatically.
- Built-in HTTPS endpoint, custom domain support, and IAM-based access control.
- Request-based and always-on CPU allocation modes.
- Supports gRPC, WebSockets, and HTTP/2 in addition to standard HTTP.
- VPC connector for private network access (Cloud SQL, internal services).

---

## Real-world usage

- Public REST and GraphQL API backends.
- Webhook handlers for GitHub, Stripe, Twilio, and SaaS integrations.
- Internal microservices behind internal load balancers.
- Event-driven integrations receiving Pub/Sub or Eventarc notifications.
- Scheduled reporting and data export jobs (Cloud Run Jobs + Cloud Scheduler).
- Authentication proxy and edge processing functions.

---

## Security and operations guidance

- Assign a dedicated, least-privilege service account per Cloud Run service.
- Set `ingress = INGRESS_TRAFFIC_INTERNAL_ONLY` for services not exposed to the internet.
- Use IAM invoker bindings (`roles/run.invoker`) rather than `allUsers` unless truly public.
- Set minimum instances only for latency-sensitive services; scale-to-zero for cost savings.
- Configure `max-instances` to protect downstream databases from connection storms.
- Use Secret Manager for credentials; mount as environment variables or volume files.
- Define liveness and startup probes for gen2 services to reduce cold-start false failures.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_cloud_run_v2_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | Deploys a Cloud Run service (HTTP / gRPC) |
| [`google_cloud_run_v2_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job) | Deploys a Cloud Run job (finite tasks) |
| [`google_cloud_run_v2_service_iam_binding`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_binding) | Controls who can invoke the service |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `run.googleapis.com` API |
| [`google_vpc_access_connector`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vpc_access_connector) | Connects Cloud Run service to a VPC network |

---

## Related Docs

- [Google Cloud Run Overview](https://cloud.google.com/run/docs)
- [Cloud Run Services vs Jobs](https://cloud.google.com/run/docs/overview/what-is-cloud-run)
- [Cloud Run Concurrency](https://cloud.google.com/run/docs/about-concurrency)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
