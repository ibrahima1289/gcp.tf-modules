# Google Cloud API Gateway

## Service Overview

[Google Cloud API Gateway](https://cloud.google.com/api-gateway/docs) is a fully managed service that enables you to create, secure, deploy, and monitor APIs for your serverless backends. It acts as a reverse proxy that sits in front of your services — Cloud Run, Cloud Functions, App Engine, or any HTTP backend — and enforces authentication, rate limiting, request transformation, and observability without requiring application-level code changes.

API Gateway uses an OpenAPI 2.0 (Swagger) spec or gRPC service configuration to define your API surface.

---

## How API Gateway Works

```text
External Client (browser, mobile app, partner)
        │
        ▼ HTTPS request
  Cloud API Gateway
  ┌──────────────────────────────────────────────┐
  │  • Auth validation (API key / JWT / OAuth2)  │
  │  • Rate limiting & quota enforcement         │
  │  • Request routing via OpenAPI spec          │
  │  • Logging → Cloud Logging                   │
  │  • Metrics → Cloud Monitoring                │
  └──────────────────────────────────────────────┘
        │
   Backend routing
   ├── Cloud Run service
   ├── Cloud Functions (gen1 or gen2)
   └── App Engine service
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **API** | The top-level resource representing a named API (e.g. `my-payments-api`). An API can have many configs. |
| **API Config** | An immutable, versioned snapshot of an OpenAPI spec. Each deploy creates a new config. |
| **Gateway** | The regional deployment of an API Config. The gateway URL is what clients call. |
| **API Key** | Simple credential that can be validated at the gateway before requests reach backends. |
| **Service Account** | The identity the gateway uses to invoke backend services (needs `roles/run.invoker` for Cloud Run). |

---

## Authentication Methods

| Method | Description | Best For |
|--------|-------------|----------|
| **API Key** | Simple key passed in `x-api-key` header or query parameter | Internal tools, partners with low-security requirements |
| **JWT / Firebase Auth** | Bearer token validated against a JWKS endpoint | Mobile apps using Firebase, Google Sign-In |
| **Google ID Token** | Service-to-service calls authenticated with a Google identity | Backend-to-backend calls within GCP |
| **OAuth 2.0** | Full delegated auth flow via Google Identity Platform | Public APIs requiring user consent |
| **No auth** | Unauthenticated passthrough (not recommended for production) | Development / testing only |

---

## OpenAPI Spec Integration

API Gateway is configured via an OpenAPI 2.0 spec with Google-specific extensions:

```yaml
swagger: "2.0"
info:
  title: My API
  version: "1.0"
host: my-gateway-id-uc.a.run.app
schemes:
  - https
paths:
  /hello:
    get:
      summary: Say hello
      operationId: sayHello
      x-google-backend:
        address: https://my-cloud-run-service-xyz-uc.a.run.app/hello
      security:
        - api_key: []
securityDefinitions:
  api_key:
    type: apiKey
    name: key
    in: query
```

Key Google extensions:

| Extension | Purpose |
|-----------|---------|
| `x-google-backend` | Routes the path to a backend URL |
| `x-google-management` | Links to a Google API management project |
| `x-google-quota` | Applies quota limits to individual methods |
| `x-google-jwt-locations` | Customises where JWT tokens are read from |

---

## Quotas and Rate Limiting

Quota limits are enforced per API key or consumer identity:

```yaml
x-google-management:
  metrics:
    - name: "my-api/requests"
      valueType: INT64
      metricKind: DELTA
  quota:
    limits:
      - name: read-limit
        metric: "my-api/requests"
        unit: "1/min/{project}"
        values:
          STANDARD: 100
```

---

## Deployment Model

```text
1. Write OpenAPI spec (api.yaml)
         │
2. Create API resource:
   gcloud api-gateway apis create my-api
         │
3. Create API Config (uploads spec):
   gcloud api-gateway api-configs create my-config \
     --api=my-api --openapi-spec=api.yaml
         │
4. Deploy Gateway (regional endpoint):
   gcloud api-gateway gateways create my-gateway \
     --api=my-api --api-config=my-config --location=us-central1
         │
5. Clients call: https://my-gateway-id-uc.a.gateway.dev/
```

---

## Regions and Availability

- API Gateway is a **regional** service; gateways are deployed to a single GCP region.
- Multiple gateways can serve the same API config for multi-region deployments.
- There is no built-in global anycast — use Cloud Load Balancing in front of multiple gateways for global distribution.

---

## Observability

| Signal | Where to View |
|--------|---------------|
| Request logs | Cloud Logging (`resource.type="apigateway.googleapis.com/Gateway"`) |
| Request count, latency, error rate | Cloud Monitoring (`apigateway.googleapis.com/gateway/*` metrics) |
| Backend latency | Logged per request in the gateway access log |
| Quota usage | API & Services → Quotas in Cloud Console |

---

## IAM Roles

| Role | Purpose |
|------|---------|
| `roles/apigateway.admin` | Full control of APIs, configs, and gateways |
| `roles/apigateway.viewer` | Read-only access |
| `roles/serviceusage.serviceUsageAdmin` | Enable/disable API Gateway service in a project |
| `roles/run.invoker` | Required on the Cloud Run backend for the gateway's service account |
| `roles/cloudfunctions.invoker` | Required on Cloud Functions backends |

---

## Pricing

| Dimension | Model |
|-----------|-------|
| API calls | Per million calls per month (tiered) |
| Free tier | First 2 million calls per month per project |
| No charge | Gateway creation, config versions, or data transfer within the same region |

> Full pricing: [https://cloud.google.com/api-gateway/pricing](https://cloud.google.com/api-gateway/pricing)

---

## Comparison: API Gateway vs Apigee vs Cloud Endpoints

| Feature | API Gateway | Apigee | Cloud Endpoints |
|---------|-------------|--------|-----------------|
| **Management overhead** | Minimal | Full enterprise platform | Low |
| **Backend support** | Cloud Run, Functions, App Engine | Any HTTP | Any HTTP |
| **Analytics portal** | Basic (Cloud Monitoring) | Advanced built-in portal | Basic |
| **Developer portal** | No | Yes | No |
| **Mediation / transformation** | Limited | Full policy engine | No |
| **Best for** | Simple serverless APIs | Enterprise API management | gRPC + REST with Endpoints framework |

---

## When to Use Cloud API Gateway

- You want a lightweight managed API layer in front of Cloud Run or Cloud Functions.
- You need API key authentication and per-consumer quotas without writing middleware.
- You are deploying internal microservice APIs and want a single managed ingress point.
- You need access logs and latency metrics without instrumenting each service individually.
- You do **not** need advanced request transformation, developer portals, or multi-environment lifecycle management (use Apigee for those).

---

## Real-World Usage

- Mobile application backend: API Gateway validates Firebase JWTs before routing to Cloud Run microservices.
- Partner integration hub: Issue API keys to third-party partners with per-key rate limits.
- Internal service mesh ingress: Centralise auth and logging for internal GKE workloads.
- Serverless monolith decomposition: Route API paths to different Cloud Functions without a code proxy.

---

## Security Guidance

- Always attach a service account to the gateway with only the `invoker` role on the backend services — never `Editor` or `Owner`.
- Prefer JWT authentication over raw API keys for user-facing APIs.
- Set explicit `max_instances` on backend Cloud Run services to limit blast radius if rate limiting is misconfigured.
- Enable Cloud Logging and set up alerts on `5xx` error rate metrics.
- Rotate API keys regularly; use Secret Manager to store them in CI/CD pipelines.

---

## Terraform Resources Commonly Used

| Resource | Purpose |
|----------|---------|
| [`google_api_gateway_api`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/api_gateway_api) | Creates the top-level API resource |
| [`google_api_gateway_api_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/api_gateway_api_config) | Uploads and versions an OpenAPI spec |
| [`google_api_gateway_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/api_gateway_gateway) | Deploys the gateway to a region |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables `apigateway.googleapis.com` and `servicemanagement.googleapis.com` |
| [`google_service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) | Creates the gateway's invocation identity |

---

## Related Docs

- [Cloud API Gateway Documentation](https://cloud.google.com/api-gateway/docs)
- [OpenAPI Extensions Reference](https://cloud.google.com/api-gateway/docs/openapi-extensions)
- [API Gateway Quotas](https://cloud.google.com/api-gateway/docs/quotas)
- [Apigee Explainer](../apigee/gcp-apigee.md)
- [GCP Service List — Definitions](../../../gcp-service-list-definitions.md)
- [GCP Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
