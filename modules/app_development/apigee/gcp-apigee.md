# Google Apigee API Management

## Service Overview

[Apigee](https://cloud.google.com/apigee/docs) is Google Cloud's enterprise API management platform. It provides a full API lifecycle management solution — design, secure, analyse, monetise, and scale APIs — built on top of a distributed proxy runtime that sits between your clients and backend services.

Apigee is distinct from Cloud API Gateway in that it offers a full policy engine for request/response transformation, a built-in developer portal, advanced analytics, and multi-environment lifecycle management (development → staging → production).

---

## How Apigee Works

```text
External Client (partner, mobile app, third-party)
        │
        ▼ HTTPS
  Apigee Runtime (managed proxy)
  ┌──────────────────────────────────────────────────────────────┐
  │  PreFlow policies                                            │
  │  ├── Verify API key / OAuth token / JWT                      │
  │  ├── Quota enforcement                                       │
  │  ├── Spike arrest (burst throttling)                         │
  │  ├── JSON/XML threat protection                              │
  │  └── Request transformation (headers, body, routing)         │
  │                                                              │
  │  Target Flow → Backend service                               │
  │                                                              │
  │  PostFlow policies                                           │
  │  ├── Response transformation / masking                       │
  │  ├── Analytics data collection                               │
  │  └── CORS header injection                                   │
  └──────────────────────────────────────────────────────────────┘
        │
   Backend (Cloud Run, GKE, on-prem, any HTTP endpoint)
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Organization** | The top-level Apigee resource, tied to a GCP project. One org per GCP project. |
| **Environment** | A named runtime scope (e.g. `dev`, `staging`, `prod`). API proxies are deployed to environments. |
| **Environment Group** | A set of environments that share a common hostname; controls routing from hostnames to environments. |
| **API Proxy** | A deployable bundle of policies + routing config that mediates requests between client and backend. |
| **API Product** | A curated collection of API proxy resources packaged for consumption (used in the developer portal). |
| **Developer App** | A registered application associated with a developer and bound to API products; issues credentials. |
| **Policy** | A declarative XML-based processing step applied in flows (e.g. `VerifyAPIKey`, `OAuthV2`, `Quota`). |
| **Flow** | An ordered sequence of policy execution: PreFlow → Conditional Flows → PostFlow (per request and response). |
| **Target Server** | A named reference to a backend endpoint, decoupled from proxy config for environment-specific overrides. |
| **KVM (Key Value Map)** | A runtime-accessible key/value store for dynamic configuration within proxies. |

---

## Editions

| Edition | Description | Hosting |
|---------|-------------|---------|
| **Apigee X** | Current GA edition, fully integrated with Google Cloud. VPC-native runtime. | Google-managed on GCP |
| **Apigee hybrid** | Runtime in your own Kubernetes cluster; management plane on Google Cloud | Customer-managed k8s |
| **Apigee Edge (legacy)** | Original Apigee platform — no new features; migration to X recommended | Apigee-managed cloud |

---

## Policy Categories

| Category | Example Policies |
|----------|-----------------|
| **Security** | `VerifyAPIKey`, `OAuthV2`, `VerifyJWT`, `BasicAuthentication`, `SAML` |
| **Traffic management** | `Quota`, `SpikeArrest`, `ResponseCache`, `ConcurrentRatelimit` |
| **Mediation** | `AssignMessage`, `ExtractVariables`, `JSONToXML`, `XMLToJSON`, `XSLT` |
| **Extension** | `ServiceCallout`, `JavaCallout`, `JavaScriptCallout`, `PythonScript` |
| **Data masking** | `DataMasking` (masks sensitive fields in debug sessions and logs) |
| **Fault handling** | `RaiseFault`, `FaultRules` |

---

## API Proxy Lifecycle

```text
1. Design API proxy in Apigee Console or bundle ZIP
         │
2. Deploy to "dev" environment → integration testing
         │
3. Deploy to "staging" environment → load / security testing
         │
4. Deploy to "prod" environment → GA traffic
         │
5. Revision management — previous revisions remain deployed
         until explicitly undeployed
```

---

## Developer Portal

Apigee includes a built-in Integrated Developer Portal or can connect to a custom Drupal-based portal:

- **API catalogue**: Documents all published API products with auto-generated OpenAPI reference pages.
- **Self-service registration**: Developers register apps and receive credentials without manual admin approval.
- **API key and OAuth app management**: Developers manage their own credentials through the portal.
- **Try-it console**: Interactive API explorer backed by the live gateway.

---

## Analytics

Apigee captures per-request analytics with sub-second granularity:

| Metric | Description |
|--------|-------------|
| **API traffic** | Total requests by proxy, product, developer, app |
| **Error rate** | 4xx/5xx breakdown by policy and target |
| **Latency** | Total, proxy, and target response time percentiles |
| **Quota usage** | Remaining quota per developer app / API product |
| **Cache hit rate** | `ResponseCache` policy effectiveness |

Analytics are accessible via the Apigee Console dashboards, the Analytics API, or export to BigQuery.

---

## Monetisation

Apigee supports API monetisation (billing developers for API usage):

- Define **rate plans** tied to API products (flat fee, pay-per-call, bundles, freemium tiers).
- Integrate with payment processors.
- Generate **revenue reports** from usage data.

---

## Networking (Apigee X)

Apigee X runtime runs inside a **Google-managed VPC** that is **peered** to your project VPC:

```text
Client
  │
  ▼ Public or Private endpoint
Apigee X runtime (Google-managed VPC)
  │ VPC Peering
  ▼
Your project VPC
  └── Cloud Run / GKE / Cloud SQL backends
```

- **Northbound (client → Apigee)**: External access via global external HTTPS LB + Apigee instance IP, or internal access via PSC (Private Service Connect).
- **Southbound (Apigee → backend)**: Via VPC peering to your project VPC. Target Server addresses must be reachable within the peered network.

---

## IAM Roles

| Role | Purpose |
|------|---------|
| `roles/apigee.admin` | Full control of the Apigee organization |
| `roles/apigee.deployAdmin` | Deploy and undeploy API proxies |
| `roles/apigee.developerAdmin` | Manage developers and apps |
| `roles/apigee.analyticsViewer` | Read analytics dashboards |
| `roles/apigee.apiAdminV2` | Manage APIs and products (least privilege for CI/CD) |

---

## Pricing

| Dimension | Model |
|-----------|-------|
| **Apigee X** | Flat monthly fee per environment unit + optional add-ons (advanced analytics, monetisation) |
| **API calls** | Included up to a limit per environment; overage charged per million calls |
| **Data transfer** | Standard GCP egress rates |

> Full pricing: [https://cloud.google.com/apigee/pricing](https://cloud.google.com/apigee/pricing)

---

## When to Use Apigee

- You are building an **enterprise or partner-facing API program** with a developer portal and credentials lifecycle.
- You need **advanced traffic policies**: spike arrest, response caching, complex quota models.
- You require **request/response transformation**: JSON↔XML conversion, header manipulation, routing logic.
- You need **detailed per-developer analytics** and API monetisation.
- Your organisation has compliance requirements for **data masking** and **security policies** at the API tier.
- You do **not** need Apigee for simple internal microservice-to-microservice calls — use Cloud API Gateway or internal load balancers instead.

---

## Real-World Usage

- **Financial services**: Expose payment APIs to fintech partners with per-partner rate plans and compliance-grade data masking.
- **Retail**: Unified product catalogue API across mobile, web, and third-party integrations with canary rollout per API version.
- **Healthcare**: Patient data API with HIPAA-compliant OAuth2 flows, field-level masking, and audit logging.
- **Telco**: Expose network capability APIs to ISV ecosystem with self-service developer portal and billing integration.

---

## Security Guidance

- Use **OAuth 2.0 client credentials** or **JWT** for machine-to-machine API calls; API keys only for low-sensitivity public APIs.
- Attach **Spike Arrest** policies to every proxy to prevent upstream overload during traffic bursts.
- Use **DataMasking** to redact PII (email, SSN, card numbers) from debug sessions and access logs.
- Store backend credentials (API keys, passwords) in **KVMs encrypted at rest** or in Secret Manager with a ServiceCallout policy.
- Enforce **HTTPS only** — disable HTTP on environment groups and reject non-TLS connections at the LB tier.
- Enable **Apigee audit logs** via Cloud Audit Logs for compliance traceability.

---

## Terraform Resources Commonly Used

| Resource | Purpose |
|----------|---------|
| [`google_apigee_organization`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_organization) | Provisions the Apigee organisation linked to a GCP project |
| [`google_apigee_environment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_environment) | Creates a named environment (dev/staging/prod) |
| [`google_apigee_environment_group`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_envgroup) | Groups environments under shared hostnames |
| [`google_apigee_environment_group_attachment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_envgroup_attachment) | Attaches an environment to an environment group |
| [`google_apigee_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_instance) | Provisions a regional Apigee X runtime instance |
| [`google_apigee_instance_attachment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/apigee_instance_attachment) | Attaches a runtime instance to an environment |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables `apigee.googleapis.com` and required APIs |

---

## Related Docs

- [Apigee X Documentation](https://cloud.google.com/apigee/docs)
- [Apigee Policy Reference](https://cloud.google.com/apigee/docs/api-platform/reference/policies/reference-overview-policy)
- [Apigee X Networking](https://cloud.google.com/apigee/docs/api-platform/get-started/vpc-peering)
- [Apigee vs API Gateway](https://cloud.google.com/blog/products/api-management/understanding-apigee-and-cloud-endpoints)
- [API Gateway Explainer](../api_gateway/gcp-api-gateway.md)
- [GCP Service List — Definitions](../../../gcp-service-list-definitions.md)
- [GCP Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
