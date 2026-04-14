# Google Cloud Batch

## Service overview

[Google Cloud Batch](https://cloud.google.com/batch/docs) is a fully managed batch workload scheduler and executor. You define jobs composed of tasks, and Cloud Batch automatically provisions compute resources, schedules task execution, handles retries on failures, and tears down resources when work is complete. It supports Spot VMs for significant cost reduction on fault-tolerant workloads.

---

## How Cloud Batch works

A Batch job is structured as a hierarchy:

```text
Job
└── Task Group (one or more)
    └── Tasks (one or more independent units of work)
        └── Runnables (scripts, containers, or barrier steps)
```

- **Job** — top-level scheduling unit with lifecycle, retry, and resource policies
- **Task Group** — a set of parallel tasks sharing compute specifications
- **Task** — a single work unit; tasks in a group can run in parallel or sequentially
- **Runnable** — the actual work: a container image, a shell script, or a barrier

Cloud Batch provisions a Managed Instance Group (MIG) of VMs to run the tasks, then automatically deletes the instances when all tasks are complete.

---

## Job components

| Component | Description |
|-----------|-------------|
| **Job** | Top-level resource with scheduling policies, retry counts, timeout, and priority |
| **Task group** | Defines parallelism (how many tasks run simultaneously) and task count |
| **Task** | One unit of work; receives a `BATCH_TASK_INDEX` environment variable to identify itself |
| **Runnable** | Container, script, or barrier; a task can have multiple runnables run in sequence |
| **Allocation policy** | Defines VM type, disk, network, and Spot vs on-demand selection |
| **Log policy** | Controls where task stdout/stderr is sent (Cloud Logging, GCS bucket, or none) |

---

## Job lifecycle states

| State | Description |
|-------|-------------|
| **QUEUED** | Job is accepted and waiting for resources |
| **SCHEDULED** | Resources are being allocated |
| **RUNNING** | One or more tasks are executing |
| **SUCCEEDED** | All tasks completed successfully |
| **FAILED** | One or more tasks failed beyond retry limit |
| **DELETION_IN_PROGRESS** | Job is being deleted |

---

## Compute options

| Option | Description | Best for |
|--------|-------------|----------|
| **On-demand VMs** | Standard pricing, no preemption risk | Critical deadline-bound jobs |
| **Spot VMs** | Up to 91% discount, may be preempted | Fault-tolerant jobs, bulk processing |
| **Custom machine types** | Precise vCPU/memory allocation | Memory- or CPU-specific workloads |
| **GPU-attached VMs** | A2/A3/G2 with NVIDIA GPUs | ML inference/training batch jobs |
| **Accelerator count** | Multiple GPUs per VM | Large model training or rendering |

---

## Scheduling and retry policies

| Policy | Description |
|--------|-------------|
| **Max retry count** | Number of times a failed task is retried before marking as failed |
| **Max run duration** | Maximum wall-clock time allowed per task before forced termination |
| **Task parallelism** | Number of tasks from a group that can execute simultaneously |
| **Scheduling priority** | 0–99 numeric priority (higher = higher priority) for queue ordering |

---

## When to use Cloud Batch

- Workloads run asynchronously and tolerate queued execution.
- Jobs can be parallelized into many independent tasks (array jobs).
- You need managed retries, timeout enforcement, and job-state tracking.
- Compute must be ephemeral — provision when running, delete when done.
- Cost efficiency matters and Spot VMs are acceptable.

---

## Core capabilities

- Large-scale job scheduling with parallel task execution.
- Flexible compute: on-demand VMs, Spot VMs, GPU-attached VMs.
- Retry, timeout, and priority controls for resilient workflows.
- Container-native: run Docker images directly or shell scripts.
- Array jobs: process thousands of indexed tasks from one job definition.
- Native integration with Cloud Logging, Cloud Monitoring, and Pub/Sub.

---

## Real-world usage

- Nightly ETL data cleanup, transformations, and backfills.
- Large-scale scientific simulation and Monte Carlo runs.
- Rendering, media transcoding, and document conversion pipelines.
- ML data preprocessing and feature engineering pipelines.
- Genomics and bioinformatics workflows processing large sample sets.
- Automated testing across parameterized configurations.

---

## Security and operations guidance

- Assign a dedicated, least-privilege service account to each job; do not use the default compute SA.
- Define explicit `max_retry_count`, `max_run_duration`, and task parallelism to prevent runaway jobs.
- Use separate job queues (projects or labels) for critical and non-critical workloads.
- Apply labels for ownership, team, and cost attribution; export billing by label.
- Store task scripts in versioned GCS buckets, not inline, for auditability.
- Enable Cloud Logging for job output; review failed task logs before retrying manually.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_batch_job`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/batch_job) | Define and submit a batch job with all task/VM configuration |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables the `batch.googleapis.com` API |
| [`google_service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) | Dedicated service account for job VMs |
| [`google_storage_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | GCS bucket for task scripts and output data |

---

## Related Docs

- [Google Cloud Batch Overview](https://cloud.google.com/batch/docs)
- [Cloud Batch Job Concepts](https://cloud.google.com/batch/docs/get-started)
- [Cloud Batch Pricing](https://cloud.google.com/batch/pricing)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
