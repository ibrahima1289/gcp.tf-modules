# Google App Engine

## Service overview

[Google App Engine](https://cloud.google.com/appengine/docs) is a fully managed Platform-as-a-Service (PaaS) for deploying web applications and APIs. Google manages the infrastructure, OS, runtime patching, and scaling automatically. You deploy application code (or containers in Flexible mode), and App Engine handles the rest.

App Engine was Google Cloud's original serverless platform and remains widely used for web applications that fit a runtime-centric deployment model. For new greenfield projects, Cloud Run is often preferred due to its container-native portability, but App Engine's deep integration with traffic splitting, versioning, and managed runtimes makes it a strong choice for many workloads.

---

## How App Engine works

```text
app.yaml / Dockerfile
      |
gcloud app deploy (or CI/CD pipeline)
      |
App Engine Application (one per project)
  ├── Default Service
  ├── API Service
  └── Worker Service
      |
Each Service has multiple Versions
  └── Traffic split across versions (e.g., 95% v2, 5% v3 canary)
```

An **App Engine Application** is a singleton per project. Within it:
- **Services** map to independent components of your application (e.g., frontend, backend, worker)
- **Versions** are immutable deployments; you can split traffic across versions for canary testing
- **Instances** are the underlying VMs or sandboxes that handle requests, scaled automatically

---

## Standard vs Flexible environment

| Dimension | Standard Environment | Flexible Environment |
|-----------|---------------------|---------------------|
| **Infrastructure** | Google-managed sandboxes | Docker containers on Compute Engine VMs |
| **Startup time** | Milliseconds (instance warm-up fast) | Minutes (VM-based) |
| **Scale to zero** | Yes (free tier applies) | No minimum 1 instance |
| **Runtime support** | Specific language versions (see below) | Any language via custom Dockerfile |
| **Max request timeout** | 10 minutes (automatic scaling) | 60 minutes |
| **Background threads** | Limited (sandbox restrictions) | Full OS capabilities |
| **Local disk** | Ephemeral, read-only filesystem | Read/write disk |
| **Best for** | Low-latency web apps, APIs, scale-to-zero | Long-running processes, custom dependencies |

---

## Supported runtimes (Standard)

| Runtime | Supported versions |
|---------|--------------------|
| Python | 3.11, 3.12 |
| Java | 11, 17, 21 |
| Node.js | 20, 22 |
| Go | 1.21, 1.22 |
| PHP | 8.2, 8.3 |
| Ruby | 3.2, 3.3 |

> For Flexible, any runtime is supported via custom Dockerfile.

---

## Scaling types

| Scaling type | Behavior | Best for |
|-------------|----------|----------|
| **Automatic** | Scales instances based on request load; scales to zero | Variable traffic, cost-optimized APIs |
| **Basic** | Scales on demand; instances created per request (slower) | Occasional/intermittent workloads |
| **Manual** | Fixed instance count; no automatic scaling | Predictable load, background services |

---

## Traffic splitting methods

| Method | Description |
|--------|-------------|
| **IP-based** | Routes users to the same version based on IP hash |
| **Cookie-based** | Uses `GOOGAPPUID` cookie for session stickiness |
| **Random** | No affinity; evenly distributes across versions |

---

## When to use App Engine

- You need rapid application deployment with minimal operations overhead.
- Your application fits a supported standard runtime for fastest cold starts.
- You prefer versioned deployments and simple traffic splitting via the CLI/SDK.
- You are maintaining existing App Engine apps or migrating them incrementally.

---

## Core capabilities

- Automatic scaling based on incoming request demand.
- Built-in versioning with zero-downtime traffic migration.
- Standard and Flexible runtime choices.
- Integrated Cloud Logging, Error Reporting, and Cloud Trace.
- IAM-governed access control at service and version level.
- Firewall rules for controlling inbound traffic.

---

## Real-world usage

- Internal admin portals and dashboards with variable daily demand.
- Business APIs with straightforward CI/CD flow and no container expertise.
- Legacy PaaS applications originally deployed on Heroku or similar.
- Multi-service microapps using App Engine service-to-service calls.
- Cron job execution using App Engine scheduled tasks.

---

## Security and operations guidance

- Keep application services stateless; externalize all session and application state.
- Assign a dedicated, least-privilege service account per App Engine service.
- Separate development, staging, and production deployments across projects.
- Use App Engine firewall rules to restrict inbound IP ranges for internal services.
- Rotate service account keys and use Secret Manager for sensitive credentials.
- Use Cloud Logging and Error Reporting for continuous reliability checks.
- Set `max_instances` in `automatic_scaling` to prevent over-provisioning costs.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_app_engine_application`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application) | Creates the App Engine application in a project |
| [`google_app_engine_standard_app_version`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_standard_app_version) | Deploys a version on the Standard environment |
| [`google_app_engine_flexible_app_version`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_flexible_app_version) | Deploys a version on the Flexible environment |
| [`google_app_engine_service_split_traffic`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_service_split_traffic) | Manages traffic splitting across versions |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `appengine.googleapis.com` API |

---

## Related Docs

- [Google App Engine Overview](https://cloud.google.com/appengine/docs)
- [Standard vs Flexible Environments](https://cloud.google.com/appengine/docs/the-appengine-environments)
- [App Engine Scaling](https://cloud.google.com/appengine/docs/standard/scaling-settings)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
