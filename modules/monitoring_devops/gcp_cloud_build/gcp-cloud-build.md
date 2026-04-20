# Google Cloud Build

[Cloud Build](https://cloud.google.com/build/docs) is a fully managed CI/CD platform that executes builds as a series of steps in isolated containers. It integrates with GitHub, GitLab, Bitbucket, and Cloud Source Repositories to trigger builds on push/PR events, and produces artifacts that can be pushed to Artifact Registry, deployed to Cloud Run, GKE, or App Engine, or passed downstream in a Cloud Deploy pipeline.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Managed build execution** | Each step runs in a Docker container; no infrastructure to manage |
| **Concurrent steps** | Steps can run in parallel using `waitFor` dependencies |
| **Substitutions** | Variable injection at build time (`$PROJECT_ID`, `$SHORT_SHA`, custom vars) |
| **Triggers** | Webhook, push-to-branch, tag, PR, manual, Pub/Sub, scheduled |
| **Private pools** | Dedicated build workers in your VPC for private network access |
| **Artifact publishing** | Push Docker images to Artifact Registry; upload files to GCS |
| **SLSA provenance** | Generate build provenance attestations for supply chain security |
| **Secret integration** | Reference Secret Manager secrets directly in build steps |

---

## Core Concepts

### Build Configuration (`cloudbuild.yaml`)

```yaml
steps:
  # Step 1: Run tests
  - name: 'golang:1.22'
    id: test
    entrypoint: go
    args: ['test', './...']

  # Step 2: Build Docker image (can run after test)
  - name: 'gcr.io/cloud-builders/docker'
    id: build
    args:
      - build
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repo/my-app:$SHORT_SHA'
      - '.'
    waitFor: ['test']

  # Step 3: Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    id: push
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repo/my-app:$SHORT_SHA']
    waitFor: ['build']

substitutions:
  _ENVIRONMENT: staging

options:
  logging: CLOUD_LOGGING_ONLY
  machineType: E2_HIGHCPU_8

timeout: 1200s

images:
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repo/my-app:$SHORT_SHA'
```

### Build Triggers

```hcl
# Trigger on push to main branch
resource "google_cloudbuild_trigger" "main_push" {
  name        = "main-branch-build"
  description = "Build and push on push to main"
  project     = var.project_id
  location    = "us-central1"

  github {
    owner = "my-org"
    name  = "my-repo"
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ENVIRONMENT = "production"
  }

  service_account = google_service_account.cloudbuild.id

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

# Trigger on new tag
resource "google_cloudbuild_trigger" "tag_release" {
  name     = "release-tag-build"
  project  = var.project_id
  location = "us-central1"

  github {
    owner = "my-org"
    name  = "my-repo"
    push {
      tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    }
  }

  filename = "cloudbuild.yaml"
}
```

### Service Account and IAM

By default, Cloud Build uses the project's **Cloud Build service account** (`[PROJECT_NUMBER]@cloudbuild.gserviceaccount.com`). For tighter control, create a dedicated SA:

```hcl
resource "google_service_account" "cloudbuild" {
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
}

# Allow pushing to Artifact Registry
resource "google_project_iam_member" "ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# Allow reading secrets
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# Allow deploying to Cloud Run
resource "google_project_iam_member" "run_deployer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}
```

### Accessing Secrets in Build Steps

```yaml
steps:
  - name: 'bash'
    secretEnv: ['DB_PASSWORD']
    script: |
      echo "Connecting with password: $$DB_PASSWORD"

availableSecrets:
  secretManager:
    - versionName: projects/$PROJECT_ID/secrets/db-password/versions/latest
      env: DB_PASSWORD
```

### Private Pools

For builds that need to access private VPC resources (Cloud SQL, internal APIs):

```hcl
resource "google_cloudbuild_worker_pool" "private" {
  name     = "private-pool"
  location = "us-central1"

  worker_config {
    disk_size_gb   = 100
    machine_type   = "e2-standard-4"
    no_external_ip = true   # no internet access; use VPC peering
  }

  network_config {
    peered_network          = google_compute_network.build_vpc.id
    peered_network_ip_range = "/29"
  }
}
```

### Build Machine Types

| Machine Type | vCPU | RAM | Notes |
|-------------|------|-----|-------|
| `E2_STANDARD_2` | 2 | 8 GB | Default |
| `E2_STANDARD_4` | 4 | 16 GB | |
| `E2_HIGHCPU_8` | 8 | 8 GB | Good for CPU-bound compiles |
| `E2_HIGHCPU_32` | 32 | 32 GB | Large builds |
| `N1_HIGHCPU_8` | 8 | 8 GB | Legacy N1 |
| `N1_HIGHCPU_32` | 32 | 29 GB | Large N1 |

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_cloudbuild_trigger` | Create build triggers (push, tag, PR, manual, scheduled) |
| `google_cloudbuild_worker_pool` | Create private build worker pools |
| `google_cloudbuild_bitbucket_server_config` | Connect Bitbucket Server to Cloud Build |
| `google_cloudbuild_github_enterprise_config` | Connect GitHub Enterprise to Cloud Build |

---

## Security Guidance

- Use a **dedicated service account** per trigger instead of the default Cloud Build SA — apply least-privilege roles.
- Never embed secrets in `cloudbuild.yaml`; use `availableSecrets` with **Secret Manager** references.
- Enable **SLSA provenance** generation for container images to establish build attestation for supply chain security.
- Use **private pools** when builds need access to private databases, internal APIs, or restricted VPCs.
- Set `no_external_ip = true` on private pools and route internet access via **Cloud NAT** to control egress.
- Restrict `roles/cloudbuild.builds.editor` to CI automation only; `roles/cloudbuild.builds.viewer` for developers.
- Enable **Cloud Audit Logs** (Admin Activity + Data Access) for `cloudbuild.googleapis.com` to track trigger changes.

---

## Related Docs

- [Cloud Build Overview](https://cloud.google.com/build/docs/overview)
- [Build Configuration Reference](https://cloud.google.com/build/docs/build-config-file-schema)
- [Cloud Build Triggers](https://cloud.google.com/build/docs/triggers)
- [Private Pools](https://cloud.google.com/build/docs/private-pools/private-pools-overview)
- [SLSA Provenance](https://cloud.google.com/build/docs/securing-builds/generate-provenance)
- [Pricing](https://cloud.google.com/build/pricing)
- [google_cloudbuild_trigger](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger)
- [google_cloudbuild_worker_pool](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_worker_pool)
