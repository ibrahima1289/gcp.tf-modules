# Google Artifact Registry

[Artifact Registry](https://cloud.google.com/artifact-registry/docs) is Google Cloud's fully managed artifact management service. It stores, organizes, and secures container images, language packages (Maven, npm, PyPI, Go, Ruby, NuGet, Apt, Yum), and generic files. It replaces Container Registry and integrates natively with Cloud Build, Cloud Deploy, GKE, Cloud Run, and binary authorization workflows.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Multi-format support** | Docker, Maven, npm, PyPI, Go modules, NuGet, Composer, Apt, Yum, generic files |
| **Regional repositories** | Data stored in a single region; no unintended cross-region transfer |
| **IAM access control** | Fine-grained per-repository IAM; supports Workload Identity |
| **Vulnerability scanning** | On-push scanning via Container Analysis (CVE database) |
| **CMEK encryption** | Customer-managed encryption keys via Cloud KMS |
| **VPC Service Controls** | Enforce perimeter for artifact access |
| **Remote repositories** | Proxy and cache upstream public registries (Docker Hub, PyPI, npm, Maven Central) |
| **Virtual repositories** | Merge multiple upstream repos into a single logical endpoint |
| **Cleanup policies** | Automated deletion of old/untagged artifacts |

---

## Core Concepts

### Repository Formats

| Format | Host URL Pattern | Use Case |
|--------|-----------------|---------|
| Docker | `REGION-docker.pkg.dev/PROJECT/REPO` | Container images |
| Maven | `REGION-maven.pkg.dev/PROJECT/REPO` | Java/JVM packages |
| npm | `REGION-npm.pkg.dev/PROJECT/REPO` | Node.js packages |
| PyPI | `REGION-python.pkg.dev/PROJECT/REPO` | Python packages |
| Go | `REGION-go.pkg.dev/PROJECT/REPO` | Go modules |
| NuGet | `REGION-nuget.pkg.dev/PROJECT/REPO` | .NET packages |
| Generic | `REGION-generic.pkg.dev/PROJECT/REPO` | Binary artifacts, zip files |

### Creating Repositories

```hcl
# Docker repository with vulnerability scanning and CMEK
resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = "us-central1"
  repository_id = "app-images"
  format        = "DOCKER"
  description   = "Application container images"
  mode          = "STANDARD_REPOSITORY"

  kms_key_name = google_kms_crypto_key.ar_key.id   # optional CMEK

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state             = "UNTAGGED"
      older_than            = "604800s"   # 7 days
    }
  }

  cleanup_policies {
    id     = "keep-last-10-tagged"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
}

# Remote repository — proxies Docker Hub with caching
resource "google_artifact_registry_repository" "dockerhub_proxy" {
  project       = var.project_id
  location      = "us-central1"
  repository_id = "dockerhub-proxy"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  remote_repository_config {
    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }
}

# npm package repository
resource "google_artifact_registry_repository" "npm_repo" {
  project       = var.project_id
  location      = "us-central1"
  repository_id = "npm-packages"
  format        = "NPM"
  mode          = "STANDARD_REPOSITORY"
}
```

### IAM Bindings

```hcl
# Allow Cloud Build SA to push images
resource "google_artifact_registry_repository_iam_member" "build_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# Allow GKE node SA to pull images
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}
```

### IAM Roles

| Role | Capability |
|------|-----------|
| `roles/artifactregistry.reader` | Pull artifacts (GKE nodes, Cloud Run, CD pipelines) |
| `roles/artifactregistry.writer` | Push artifacts (CI pipelines) |
| `roles/artifactregistry.repoAdmin` | Manage repository contents and settings |
| `roles/artifactregistry.admin` | Full control including repository creation/deletion |

### Configuring Docker Authentication

```bash
# Configure Docker to authenticate with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Push an image
docker push us-central1-docker.pkg.dev/my-project/app-images/my-app:v1.0.0

# Pull an image
docker pull us-central1-docker.pkg.dev/my-project/app-images/my-app:v1.0.0
```

### Vulnerability Scanning

Container Analysis scans Docker images on push:

```hcl
resource "google_project_service" "container_scanning" {
  project = var.project_id
  service = "containerscanning.googleapis.com"
}
```

View scan results:

```bash
gcloud artifacts docker images list-vulnerabilities \
  us-central1-docker.pkg.dev/my-project/app-images/my-app:v1.0.0
```

### Cleanup Policies

| Action | Condition Options |
|--------|-----------------|
| `DELETE` | `tag_state` (tagged/untagged), `older_than`, `newer_than`, `tag_prefixes`, `package_name_prefixes` |
| `KEEP` | `most_recent_versions.keep_count`, same condition options |

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_artifact_registry_repository` | Create repositories (standard, remote, virtual) |
| `google_artifact_registry_repository_iam_member` | Additive IAM bindings on a repository |
| `google_artifact_registry_repository_iam_binding` | Authoritative IAM binding on a repository |

---

## Security Guidance

- Never use `roles/artifactregistry.admin` on CI service accounts — use `roles/artifactregistry.writer` for push-only access.
- Enable **vulnerability scanning** (`containerscanning.googleapis.com`) and integrate scan results into your CI gate (fail build on CRITICAL CVEs).
- Use **remote repositories** to proxy public registries — prevents direct internet pulls, caches dependencies, and lets you audit which packages are used.
- Apply **CMEK** on repositories storing proprietary packages or regulated artifacts.
- Use **cleanup policies** to automatically remove untagged and old images; unchecked repositories can accumulate significant storage cost.
- Enforce **Binary Authorization** on GKE/Cloud Run to only allow images that passed CI from your Artifact Registry repositories.
- Enable **VPC Service Controls** to prevent exfiltration of artifacts outside your security perimeter.

---

## Related Docs

- [Artifact Registry Overview](https://cloud.google.com/artifact-registry/docs/overview)
- [Repository Formats](https://cloud.google.com/artifact-registry/docs/supported-formats)
- [Remote Repositories](https://cloud.google.com/artifact-registry/docs/repositories/remote-repos)
- [Cleanup Policies](https://cloud.google.com/artifact-registry/docs/repositories/cleanup-policy)
- [Vulnerability Scanning](https://cloud.google.com/artifact-registry/docs/analysis)
- [Pricing](https://cloud.google.com/artifact-registry/pricing)
- [google_artifact_registry_repository](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository)
