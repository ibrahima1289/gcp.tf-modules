# Google Cloud Profiler

[Cloud Profiler](https://cloud.google.com/profiler/docs) is a continuous, low-overhead statistical profiler for production workloads running on GCP. It collects CPU time, heap memory, wall time, and thread contention profiles from your application without requiring code restarts, and surfaces them as flame graphs in the Cloud Console for performance analysis.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Cloud Profiler uses **statistical sampling** — it periodically interrupts the application to capture a stack trace, then aggregates millions of samples into a flame graph that shows which code paths consume the most resources. The overhead is typically under 1% CPU, making it safe for always-on production profiling.

| Capability | Description |
|------------|-------------|
| **CPU time profiles** | Time spent executing on CPU (excludes I/O wait) |
| **Wall time profiles** | Real elapsed time including I/O, locks, and sleeps |
| **Heap profiles** | Live heap memory allocations by code path (Go, Java, Node.js) |
| **Allocated heap** | Total bytes allocated over a sample window (Go, Java) |
| **Thread profiles** | Thread contention and blocking time (Java) |
| **Flame graph UI** | Interactive call-stack visualization with filtering and comparison |
| **Continuous profiling** | Always-on; profiles collected every ~10s and aggregated |

---

## Core Concepts

### Profile Types by Language

| Language | CPU | Wall Time | Heap | Allocated Heap | Threads |
|----------|:---:|:---------:|:----:|:--------------:|:-------:|
| Go | ✅ | ✅ | ✅ | ✅ | ❌ |
| Java | ✅ | ✅ | ✅ | ✅ | ✅ |
| Node.js | ✅ | ✅ | ✅ | ❌ | ❌ |
| Python | ✅ | ✅ | ❌ | ❌ | ❌ |
| Ruby | ✅ | ❌ | ❌ | ❌ | ❌ |

### Enabling Cloud Profiler

The API must be enabled on the project:

```hcl
resource "google_project_service" "profiler" {
  project = var.project_id
  service = "cloudprofiler.googleapis.com"

  disable_on_destroy = false
}
```

### Instrumentation by Language

**Go**

```go
import "cloud.google.com/go/profiler"

func main() {
    if err := profiler.Start(profiler.Config{
        Service:        "my-service",
        ServiceVersion: "1.0.0",
        ProjectID:      "my-project",
        MutexProfiling: true,   // optional: enable mutex contention profiling
    }); err != nil {
        log.Fatalf("Cannot start profiler: %v", err)
    }
    // rest of main
}
```

**Java (agent-based)**

```bash
# Download the agent
wget -q -O- https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent.tar.gz | tar xzv -C /opt/cprof

# JVM flags
JAVA_TOOL_OPTIONS="-agentpath:/opt/cprof/profiler_java_agent.so=-cprof_service=my-service,-cprof_service_version=1.0.0"
```

**Python**

```python
import googlecloudprofiler

googlecloudprofiler.start(
    service="my-service",
    service_version="1.0.0",
    verbose=3,
    project_id="my-project",
)
```

**Node.js**

```javascript
require('@google-cloud/profiler').start({
  serviceContext: {
    service: 'my-service',
    version: '1.0.0',
  },
});
```

### Service Identity

Cloud Profiler groups profiles by `service` + `service_version` + `zone`. The running environment's service account must have:

```hcl
resource "google_project_iam_member" "profiler_agent" {
  project = var.project_id
  role    = "roles/cloudprofiler.agent"
  member  = "serviceAccount:${google_service_account.app.email}"
}
```

### Reading Profiles (Flame Graph)

The Cloud Console Profiler UI provides:

| Feature | Description |
|---------|-------------|
| **Flame graph** | Stacked call tree; width = % of total CPU/heap |
| **Filter by function** | Zoom into a specific package or function |
| **Compare profiles** | Diff two time windows to identify regressions |
| **Time range** | Select 1h / 6h / 24h / 7d aggregation windows |
| **Service filter** | Select by service name and version |

### Auto-Instrumented Environments

| Runtime | Notes |
|---------|-------|
| App Engine (standard) | Auto-enabled for Java 8, Go, Python runtimes |
| App Engine (flexible) | Add profiling agent to Dockerfile/entrypoint |
| Cloud Run | Add profiling agent to container startup; set `K_SERVICE` env var |
| GKE | Add agent to application container; no cluster-level config needed |
| Compute Engine | Add agent to VM startup script or Dockerfile |

---

## IAM Roles

| Role | Capability |
|------|-----------|
| `roles/cloudprofiler.agent` | Write profiles (application SAs) |
| `roles/cloudprofiler.user` | View profiles in the console |

---

## Security Guidance

- Grant `roles/cloudprofiler.agent` to application service accounts at the project level — do not use broad roles like `roles/editor`.
- Profile data contains stack frame names and can expose internal code structure; restrict `roles/cloudprofiler.user` to engineering teams.
- Profiling overhead is typically < 1% CPU and < 10 MB heap; validate in staging before enabling in latency-sensitive critical paths.
- Enable the `cloudprofiler.googleapis.com` API only in projects running instrumented workloads.

---

## Related Docs

- [Cloud Profiler Overview](https://cloud.google.com/profiler/docs/about-profiler)
- [Setting Up Go](https://cloud.google.com/profiler/docs/profiling-go)
- [Setting Up Java](https://cloud.google.com/profiler/docs/profiling-java)
- [Setting Up Python](https://cloud.google.com/profiler/docs/profiling-python)
- [Setting Up Node.js](https://cloud.google.com/profiler/docs/profiling-nodejs)
- [Flame Graph Interpretation](https://cloud.google.com/profiler/docs/concepts-flame)
- [Pricing](https://cloud.google.com/stackdriver/pricing#profiler)
