# Google Cloud Trace

[Cloud Trace](https://cloud.google.com/trace/docs) is a distributed tracing service that collects latency data from your applications and displays it in the Google Cloud Console. It shows how requests propagate through your services, where latency is being introduced, and which calls are slowest — enabling performance bottleneck analysis in microservice and serverless architectures.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Cloud Trace follows the **OpenTelemetry** tracing model: each request generates a **trace** composed of one or more **spans**, each representing a unit of work (an HTTP call, a database query, a function invocation). Spans are linked by a `trace_id` and form a parent-child tree that visualizes the full request lifecycle.

| Capability | Description |
|------------|-------------|
| **Distributed tracing** | Correlate spans across services via propagated trace context |
| **Latency distribution** | P50/P95/P99 histograms for request latency over time |
| **Auto-instrumentation** | Built-in tracing for Cloud Run, App Engine, Cloud Functions, GKE (with Trace agent) |
| **OpenTelemetry support** | Ingest traces via OTLP (OpenTelemetry Protocol) |
| **Trace analysis** | Filter by URL, service, status code, latency range |
| **Integration with Logging** | Correlate trace IDs with Cloud Logging entries |
| **Integration with Profiler** | Link latency spikes to CPU/heap profiles |

---

## Core Concepts

### Traces and Spans

```text
Trace (trace_id: abc123)
  ├── Span: api-gateway  [0ms → 85ms]
  │     ├── Span: auth-service  [5ms → 20ms]
  │     └── Span: backend-service  [22ms → 80ms]
  │           ├── Span: postgres-query  [25ms → 45ms]
  │           └── Span: cache-lookup  [48ms → 52ms]
```

| Concept | Description |
|---------|-------------|
| **Trace** | Complete record of a single request; identified by `traceId` (128-bit hex) |
| **Span** | A single operation within a trace; has start time, duration, labels, and status |
| **Root span** | The outermost span; typically the inbound HTTP request |
| **Child span** | Nested span representing a downstream call |
| **Trace context** | Propagated via `X-Cloud-Trace-Context` or W3C `traceparent` header |

### Enabling Trace

Cloud Trace is enabled via the `cloudtrace.googleapis.com` API. For Terraform:

```hcl
resource "google_project_service" "trace" {
  project = var.project_id
  service = "cloudtrace.googleapis.com"

  disable_on_destroy = false
}
```

No additional Terraform resource is needed — traces are written directly by applications or auto-collected by managed runtimes.

### Auto-Instrumented Runtimes

| Runtime | Trace Support |
|---------|--------------|
| Cloud Run | Automatic trace propagation; add `--set-env-vars CLOUD_TRACE_ENABLED=true` |
| App Engine (standard) | Automatic for supported runtimes (Python, Java, Go, Node.js) |
| Cloud Functions | Automatic trace header propagation |
| GKE | Requires Cloud Trace agent or OpenTelemetry collector DaemonSet |
| Compute Engine | Manual instrumentation via OpenTelemetry or client libraries |

### Manual Instrumentation (OpenTelemetry)

```python
from opentelemetry import trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

provider = TracerProvider()
provider.add_span_processor(
    BatchSpanProcessor(CloudTraceSpanExporter(project_id="my-project"))
)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("my-service")

with tracer.start_as_current_span("process-order"):
    # your logic here
    with tracer.start_as_current_span("fetch-inventory"):
        pass  # downstream call
```

### Sampling

Cloud Trace samples traces to control volume and cost. Default sampling rate varies by runtime:

| Runtime | Default Sample Rate |
|---------|-------------------|
| App Engine | All requests |
| Cloud Run | 1 in 1000 requests (configurable) |
| Manual (OTel) | Configurable via `TraceIdRatioBased` sampler |

To increase sampling for a Cloud Run service:

```bash
gcloud run services update my-service \
  --set-env-vars CLOUD_TRACE_SAMPLING_RATE=0.1   # 10%
```

### Correlating Traces with Logs

Insert the trace ID into log entries to link traces with log lines in Cloud Logging:

```python
import google.cloud.logging
from opentelemetry import trace

client = google.cloud.logging.Client()
span = trace.get_current_span()
trace_id = format(span.get_span_context().trace_id, '032x')

client.logger("my-app").log_struct(
    {"message": "Processing request"},
    trace=f"projects/my-project/traces/{trace_id}",
    span_id=format(span.get_span_context().span_id, '016x'),
    trace_sampled=True
)
```

---

## Latency Analysis

Cloud Trace Console provides:

| View | Description |
|------|-------------|
| **Trace list** | Chronological list of sampled traces with latency and status |
| **Latency distribution** | Histogram showing P50/P95/P99 for a time window |
| **Trace detail** | Waterfall diagram of all spans in a single trace |
| **Analysis reports** | Compare latency distributions across time periods |

---

## IAM Roles

| Role | Capability |
|------|-----------|
| `roles/cloudtrace.agent` | Write traces (for application SAs) |
| `roles/cloudtrace.user` | View traces in the console |
| `roles/cloudtrace.admin` | Full access including delete |

```hcl
resource "google_project_iam_member" "trace_writer" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.app.email}"
}
```

---

## Security Guidance

- Grant `roles/cloudtrace.agent` to application service accounts — not `roles/cloudtrace.admin`.
- Be cautious about trace labels — avoid including PII, session tokens, or sensitive request parameters in span attributes.
- Use **sampling** in high-volume production services to keep costs manageable; 1–5% is usually sufficient for latency analysis.
- Correlate trace IDs with Cloud Logging and Error Reporting for complete incident context.
- Enable the `cloudtrace.googleapis.com` API only in projects that run instrumented workloads.

---

## Related Docs

- [Cloud Trace Overview](https://cloud.google.com/trace/docs/overview)
- [OpenTelemetry on GCP](https://cloud.google.com/trace/docs/setup/python-ot)
- [Trace Pricing](https://cloud.google.com/stackdriver/pricing#trace-costs)
- [Correlating Logs and Traces](https://cloud.google.com/trace/docs/trace-log-integration)
- [google_project_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service)
