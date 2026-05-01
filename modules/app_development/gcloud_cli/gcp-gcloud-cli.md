# Google Cloud CLI (gcloud)

## Overview

The [Google Cloud CLI](https://cloud.google.com/sdk/gcloud) (`gcloud`) is the primary command-line interface for interacting with Google Cloud Platform resources and services. It is part of the [Google Cloud SDK](https://cloud.google.com/sdk/docs) and provides commands for managing compute instances, networking, IAM, storage, deployments, and virtually all GCP services — as well as configuration management, authentication, and scripting support for CI/CD pipelines.

> The `gcloud` CLI is not a deployable GCP resource — it is a developer and operations tool. This document covers its configuration, authentication patterns, and use within infrastructure automation workflows.

---

## Core Tool Suite

The Google Cloud SDK ships several tools alongside `gcloud`:

| Tool | Purpose |
|------|---------|
| `gcloud` | Manages GCP resources and services |
| `gsutil` | Interacts with Cloud Storage buckets (largely superseded by `gcloud storage`) |
| `bq` | BigQuery command-line tool |
| `kubectl` | Kubernetes CLI (installed separately via `gcloud components install kubectl`) |
| `gcloud storage` | Modern, high-performance Cloud Storage CLI (replaces `gsutil`) |
| `gcloud beta` / `gcloud alpha` | Access to pre-GA features |

---

## Installation

### Linux / macOS

```bash
# Download and run the installer
curl https://sdk.cloud.google.com | bash

# Restart shell and initialise
exec -l $SHELL
gcloud init
```

### Windows

Download the [Cloud SDK installer](https://cloud.google.com/sdk/docs/install-sdk#windows) (.exe) or install via Chocolatey:

```powershell
choco install gcloudsdk
```

### Docker

```bash
docker run --rm gcr.io/google.com/cloudsdktool/google-cloud-cli:latest gcloud version
```

### CI/CD (GitHub Actions)

```yaml
- uses: google-github-actions/setup-gcloud@v2
  with:
    project_id: my-gcp-project
```

---

## Authentication Modes

| Mode | Command | Use Case |
|------|---------|----------|
| **User account (interactive)** | `gcloud auth login` | Local development, manual operations |
| **Application Default Credentials (ADC)** | `gcloud auth application-default login` | SDK calls from local code (Terraform, client libraries) |
| **Service account key file** | `gcloud auth activate-service-account --key-file=key.json` | Legacy CI/CD without Workload Identity |
| **Workload Identity (GCE/GKE/Cloud Run)** | Automatic — no explicit auth needed | Running on GCP compute with attached service account |
| **Workload Identity Federation** | `gcloud iam workload-identity-pools create ...` | GitHub Actions, GitLab CI, AWS, Azure — no key files |

### Workload Identity Federation (recommended for CI/CD)

```bash
# Configure federation pool and provider
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" --project=my-gcp-project

gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"

# Bind the pool to a service account
gcloud iam service-accounts add-iam-policy-binding sa@my-gcp-project.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/my-org/my-repo"
```

---

## Configuration Management

`gcloud` supports named **configurations** — sets of project, account, and region defaults:

```bash
# Create a named configuration
gcloud config configurations create prod-config

# Set active properties
gcloud config set project my-prod-project
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud config set account admin@example.com

# Switch between configurations
gcloud config configurations activate staging-config

# List all configurations
gcloud config configurations list

# Show active config
gcloud config list
```

### Environment variable overrides

| Variable | Overrides |
|----------|-----------|
| `CLOUDSDK_CORE_PROJECT` | `gcloud config set project` |
| `CLOUDSDK_COMPUTE_REGION` | `gcloud config set compute/region` |
| `CLOUDSDK_COMPUTE_ZONE` | `gcloud config set compute/zone` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account key file for ADC |
| `GOOGLE_CLOUD_PROJECT` | Project for client library ADC |

---

## Common Command Groups

| Group | Description | Example |
|-------|-------------|---------|
| `gcloud compute` | Compute Engine VMs, disks, networks | `gcloud compute instances list` |
| `gcloud container` | GKE clusters and node pools | `gcloud container clusters get-credentials` |
| `gcloud run` | Cloud Run services and jobs | `gcloud run deploy my-svc --image ...` |
| `gcloud functions` | Cloud Functions | `gcloud functions deploy my-fn` |
| `gcloud storage` | Cloud Storage (buckets, objects) | `gcloud storage cp file.txt gs://bucket/` |
| `gcloud sql` | Cloud SQL instances | `gcloud sql instances describe my-db` |
| `gcloud iam` | IAM policies, service accounts, roles | `gcloud iam service-accounts create` |
| `gcloud projects` | Project creation and IAM | `gcloud projects list` |
| `gcloud pubsub` | Pub/Sub topics and subscriptions | `gcloud pubsub topics publish` |
| `gcloud secrets` | Secret Manager | `gcloud secrets versions access latest --secret=my-secret` |
| `gcloud logging` | Cloud Logging | `gcloud logging read "resource.type=gce_instance"` |
| `gcloud monitoring` | Alerting policies, notification channels | `gcloud monitoring channels list` |
| `gcloud builds` | Cloud Build | `gcloud builds submit --tag gcr.io/proj/img` |
| `gcloud artifacts` | Artifact Registry | `gcloud artifacts repositories list` |
| `gcloud deploy` | Cloud Deploy pipelines | `gcloud deploy releases create` |
| `gcloud services` | API enablement | `gcloud services enable run.googleapis.com` |

---

## Output Formats

```bash
# Table (default)
gcloud compute instances list

# JSON — for scripting and parsing with jq
gcloud compute instances list --format=json

# YAML
gcloud compute instances describe my-vm --format=yaml

# Value — extract a single field
gcloud compute instances describe my-vm --format="value(networkInterfaces[0].accessConfigs[0].natIP)"

# CSV
gcloud compute instances list --format="csv(name,zone,status)"

# Filter results
gcloud compute instances list --filter="zone:us-central1-a AND status=RUNNING"
```

---

## Scripting and Automation

```bash
# Wait for an operation to complete
gcloud compute instances create my-vm --zone=us-central1-a
gcloud compute instances describe my-vm --zone=us-central1-a --format="value(status)"

# Quiet mode — suppress prompts for scripting
gcloud compute instances delete my-vm --zone=us-central1-a --quiet

# Impersonate a service account (no key file required)
gcloud compute instances list \
  --impersonate-service-account=deployer@my-project.iam.gserviceaccount.com

# Generate an access token for API calls
TOKEN=$(gcloud auth print-access-token)
curl -H "Authorization: Bearer $TOKEN" https://compute.googleapis.com/compute/v1/projects/my-proj/zones

# Print identity token (for Cloud Run invoke)
gcloud auth print-identity-token
```

---

## Terraform Integration

`gcloud` is commonly used alongside Terraform:

| Use | Command |
|-----|---------|
| Authenticate Terraform via ADC | `gcloud auth application-default login` |
| Set up GKE kubeconfig after `terraform apply` | `gcloud container clusters get-credentials CLUSTER --region REGION` |
| Enable APIs before running Terraform | `gcloud services enable container.googleapis.com` |
| Impersonate service account in CI/CD | `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=deployer@proj.iam.gserviceaccount.com terraform plan` |

---

## Components Management

```bash
# List available components
gcloud components list

# Install additional components
gcloud components install kubectl
gcloud components install terraform-tools
gcloud components install alpha beta

# Update all components
gcloud components update

# Remove a component
gcloud components remove gsutil
```

---

## Logging and Diagnostics

```bash
# View gcloud debug logs
gcloud --log-http compute instances list

# Show current authentication
gcloud auth list

# Show SDK version
gcloud version

# Diagnose environment issues
gcloud info
```

---

## Security Guidance

- **Never commit service account key JSON files** to source control. Use Workload Identity Federation for CI/CD.
- Use `gcloud auth application-default login` for local Terraform/SDK development — credentials are stored in `~/.config/gcloud/` and are user-scoped.
- Use `--impersonate-service-account` to test permissions without switching credentials — requires `roles/iam.serviceAccountTokenCreator`.
- Audit `gcloud` usage via **Cloud Audit Logs** — all API calls made by `gcloud` are logged as data access or admin activity.
- Rotate or delete service account keys regularly; prefer keyless Workload Identity wherever possible.

---

## Related Docs

- [Google Cloud CLI Documentation](https://cloud.google.com/sdk/gcloud/reference)
- [Cloud SDK Installation](https://cloud.google.com/sdk/docs/install)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
- [gcloud Output Formats](https://cloud.google.com/sdk/gcloud/reference/topic/formats)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
- [GCP Service List — Definitions](../../../gcp-service-list-definitions.md)
