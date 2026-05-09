# GCP Ops Agent

The [Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent) is the **primary agent** for collecting telemetry from Compute Engine VMs. It unifies metric collection (via OpenTelemetry Collector) and log collection (via Fluent Bit) in a single binary, replacing the older Stackdriver Monitoring Agent and Stackdriver Logging Agent.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Detail |
|------------|--------|
| **Supported OS** | Debian, Ubuntu, RHEL, CentOS, Rocky, SLES, Windows Server |
| **Metrics backend** | [Cloud Monitoring](https://cloud.google.com/monitoring) via OpenTelemetry Collector pipeline |
| **Logs backend** | [Cloud Logging](https://cloud.google.com/logging) via Fluent Bit pipeline |
| **Configuration** | YAML file at `/etc/google-cloud-ops-agent/config.yaml` (Linux) or `C:\Program Files\Google\Cloud Operations\Ops Agent\config\config.yaml` (Windows) |
| **Terraform resource** | [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) with `metadata_startup_script` or `google_os_config_os_policy_assignment` |
| **Auto-install** | Available via [VM Manager OS policies](https://cloud.google.com/compute/docs/manage-os) or startup scripts |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        Compute Engine VM                           │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                        Ops Agent                            │   │
│  │                                                             │   │
│  │  ┌────────────────────────┐  ┌──────────────────────────┐   │   │
│  │  │  Metrics sub-agent     │  │   Logs sub-agent         │   │   │
│  │  │  (OpenTelemetry        │  │   (Fluent Bit)           │   │   │
│  │  │   Collector)           │  │                          │   │   │
│  │  │                        │  │  receivers:              │   │   │
│  │  │  receivers:            │  │  ├── files (tail)        │   │   │
│  │  │  ├── hostmetrics       │  │  ├── syslog              │   │   │
│  │  │  ├── iis (Windows)     │  │  ├── windows_event_log   │   │   │
│  │  │  ├── mssqlserver       │  │  └── third-party plugins │   │   │
│  │  │  └── third-party       │  │                          │   │   │
│  │  │      (nginx, mysql…)   │  │  processors:             │   │   │
│  │  │                        │  │  └── parse_json / regex  │   │   │
│  │  │  exporters:            │  │                          │   │   │
│  │  │  └── googlecloud       │  │  exporters:              │   │   │
│  │  └────────────┬───────────┘  └───────────┬──────────────┘   │   │
│  │               │                          │                  │   │
│  └───────────────┼──────────────────────────┼──────────────────┘   │
│                  │                          │                      │
└──────────────────┼──────────────────────────┼──────────────────────┘
                   ▼                          ▼
         ┌───────────────────┐        ┌───────────────────┐
         │  Cloud Monitoring │        │  Cloud Logging    │
         │  (metrics store)  │        │  (log store)      │
         └───────────────────┘        └───────────────────┘
                   │                           │
                   ▼                           ▼
             Alert policies             Log-based metrics
             Dashboards                 Log sinks (GCS/BQ)
             Uptime checks              Error Reporting
```

---

## Core Concepts

### Sub-agents

The Ops Agent runs two internal pipelines:

| Sub-agent | Technology | Purpose |
|-----------|------------|---------|
| **Metrics** | OpenTelemetry Collector | Collects host metrics (CPU, memory, disk, network) and application-level metrics via third-party receivers |
| **Logs** | Fluent Bit | Tails log files, parses structured/unstructured logs, and ships to Cloud Logging |

Both sub-agents are configured from the **same** `config.yaml` file under their respective `metrics` and `logging` top-level keys.

### Configuration Structure

```yaml
# /etc/google-cloud-ops-agent/config.yaml

logging:
  receivers:
    my_app_logs:
      type: files
      include_paths:
        - /var/log/my-app/*.log
  processors:
    parse_json:
      type: parse_json
  service:
    pipelines:
      my_pipeline:
        receivers: [my_app_logs]
        processors: [parse_json]

metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
    nginx:
      type: nginx
      stub_status_url: http://localhost/nginx_status
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics, nginx]
```

> The built-in `default_pipeline` for both metrics and logs is active even without a custom config file. Override it only when you need to **replace** the default collection.

### Receivers

**Metrics receivers** (selected):

| Receiver type | Collects |
|---------------|---------|
| `hostmetrics` | CPU, memory, disk I/O, network I/O, filesystem, swap, load (Linux & Windows) |
| `nginx` | Active connections, requests/s, reading/writing/waiting workers |
| `apache` | Requests/s, bytes/s, worker states |
| `mysql` | InnoDB buffer pool, queries/s, connections, replication lag |
| `postgresql` | Connections, blocks read/written, rows fetched/returned |
| `redis` | Memory, commands/s, keyspace hits/misses, replication offset |
| `mongodb` | Operations, connections, document operations, lock wait time |
| `elasticsearch` | Index stats, JVM heap, thread pool queue depths |
| `jvm` | Heap memory, GC pause time, loaded class count, thread count |
| `iis` | (Windows) Request rate, byte rate, connection states |
| `mssqlserver` | (Windows) Transactions/s, lock waits, buffer cache hits |

**Log receivers** (selected):

| Receiver type | Collects |
|---------------|---------|
| `files` | Arbitrary log files (glob paths supported) |
| `syslog` | Syslog UDP/TCP stream |
| `windows_event_log` | (Windows) Application, System, Security event channels |
| `tcp` / `udp` | Raw TCP/UDP streams |

### Processors

| Processor type | Purpose |
|----------------|---------|
| `parse_json` | Parse log record body as JSON; fields become log entry labels |
| `parse_regex` | Extract named groups from log body using a RE2 regex |
| `exclude_logs` | Drop log records matching a filter expression |
| `modify_fields` | Add, rename, or delete fields on log records |

### Self-managed vs Auto-managed installation

| Method | When to use |
|--------|-------------|
| **Startup script** (`metadata_startup_script`) | Simple, single-VM, fast iteration |
| **VM Manager OS Policy** (`google_os_config_os_policy_assignment`) | Fleet-scale, enforced compliance, automatic remediation |
| **Custom image** (pre-baked) | Immutable infrastructure, fastest boot |
| **Cloud-init / Ansible** | Multi-cloud or existing config-management pipeline |

---

## Terraform Integration

The Ops Agent itself has no dedicated Terraform resource — it is installed **on the VM** rather than managed as a standalone GCP API resource. The two main Terraform patterns are:

### Pattern 1 — Startup script

```hcl
resource "google_compute_instance" "web" {
  name         = "web-01"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params { image = "debian-cloud/debian-12" }
  }

  network_interface {
    network    = "default"
    access_config {}
  }

  # Install and start Ops Agent on first boot.
  metadata_startup_script = <<-EOT
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT
}
```

### Pattern 2 — OS Config Policy (fleet-scale)

```hcl
resource "google_os_config_os_policy_assignment" "ops_agent" {
  name     = "install-ops-agent"
  location = "us-central1-a"

  instance_filter {
    # Target all VMs with the label ops-agent=enabled.
    inventories {
      os_short_name = "debian"
      os_version    = "12"
    }
  }

  os_policies {
    id   = "install-ops-agent"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "ops-agent-pkg"
        pkg {
          desired_state = "INSTALLED"
          apt {
            name = "google-cloud-ops-agent"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget { percent = 10 }
    min_wait_duration = "60s"
  }
}
```

### Pattern 3 — Custom config via `google_compute_instance` metadata

```hcl
locals {
  ops_agent_config = yamlencode({
    logging = {
      receivers = {
        app_logs = {
          type          = "files"
          include_paths = ["/var/log/app/*.log"]
        }
      }
      service = {
        pipelines = {
          app_pipeline = {
            receivers = ["app_logs"]
          }
        }
      }
    }
    metrics = {
      receivers = {
        hostmetrics = {
          type                = "hostmetrics"
          collection_interval = "60s"
        }
      }
      service = {
        pipelines = {
          default_pipeline = {
            receivers = ["hostmetrics"]
          }
        }
      }
    }
  })
}

resource "google_compute_instance" "app" {
  name         = "app-01"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params { image = "debian-cloud/debian-12" }
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Install Ops Agent.
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install

    # Write custom configuration.
    cat <<'YAML' > /etc/google-cloud-ops-agent/config.yaml
    ${local.ops_agent_config}
    YAML

    # Restart to pick up new config.
    systemctl restart google-cloud-ops-agent
  EOT
}
```

---

## Required IAM Roles

The VM's service account needs the following roles to ship telemetry:

| Role | Purpose |
|------|---------|
| `roles/monitoring.metricWriter` | Write metrics to Cloud Monitoring |
| `roles/logging.logWriter` | Write logs to Cloud Logging |
| `roles/stackdriver.resourceMetadata.writer` | Write VM metadata for resource enrichment (optional but recommended) |

```hcl
resource "google_project_iam_member" "ops_agent_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "ops_agent_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}
```

---

## Key Metrics Collected by Default

| Metric | Description |
|--------|-------------|
| `agent.googleapis.com/cpu/utilization` | Per-CPU utilisation (%) |
| `agent.googleapis.com/memory/bytes_used` | Memory used by state (buffered, cached, free, slab, used) |
| `agent.googleapis.com/disk/read_bytes_count` | Disk bytes read per second |
| `agent.googleapis.com/disk/write_bytes_count` | Disk bytes written per second |
| `agent.googleapis.com/network/tcp_connections_count` | TCP connections by state |
| `agent.googleapis.com/processes/count_by_state` | Running, sleeping, zombie process count |

> Metric prefix: `agent.googleapis.com/` (hostmetrics). Third-party receiver metrics use `agent.googleapis.com/<receiver>/`.

---

## Logging Best Practices

| Practice | Detail |
|----------|--------|
| **Structured logs** | Use `parse_json` processor — structured logs are queryable by field in Cloud Logging |
| **Log severity** | Map your app's log level to Cloud Logging severity via `modify_fields` processor |
| **Exclude noisy logs** | Use `exclude_logs` processor with a `match_any` condition to drop health-check and debug lines before they leave the VM |
| **Log rotation** | Ensure log files are rotated; Ops Agent tracks inode so rotation is handled automatically |
| **Buffer limits** | Fluent Bit buffers to disk (`/var/lib/google-cloud-ops-agent/`) by default — ensure adequate disk space |

---

## Troubleshooting

| Symptom | Cause | Resolution |
|---------|-------|------------|
| No metrics in Cloud Monitoring | Missing `monitoring.metricWriter` role | Attach role to VM service account |
| No logs in Cloud Logging | Missing `logging.logWriter` role | Attach role to VM service account |
| Agent not running | Service not started / install failed | `systemctl status google-cloud-ops-agent` |
| Config parse error | YAML syntax error | `google-cloud-ops-agent-diagnostics` tool; check `/var/log/google-cloud-ops-agent/subagents/` |
| High agent CPU/memory | Too many log files being tailed | Scope `include_paths` more narrowly; increase `collection_interval` for metrics |
| Logs missing fields | No `parse_json` processor | Add `parse_json` to the pipeline processors |

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | VM where the Ops Agent is installed via startup script |
| [`google_os_config_os_policy_assignment`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/os_config_os_policy_assignment) | Fleet-scale agent installation via OS Config VM Manager |
| [`google_project_iam_member`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam) | Grant `metricWriter` and `logWriter` to the VM service account |
| [`google_service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) | Dedicated service account for the VM (Workload Identity best practice) |

---

## Related Docs

- [Cloud Monitoring Explainer](../gcp_cloud_monitoring/gcp-cloud-monitoring.md)
- [Cloud Logging Explainer](../gcp_cloud_logging/gcp-cloud-logging.md)
- [GCP Cloud Monitoring Module](../gcp_cloud_monitoring/README.md)
- [GCP Cloud Logging Module](../gcp_cloud_logging/README.md)
- [Ops Agent official docs](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent)
- [Ops Agent supported receivers](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/third-party)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
