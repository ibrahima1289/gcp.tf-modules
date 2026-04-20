# Cloud Source Repositories

[Cloud Source Repositories](https://cloud.google.com/source-repositories/docs) is a fully managed private Git service hosted on Google Cloud. It provides unlimited repositories, IAM-native access control, integration with Cloud Build triggers, and mirroring from GitHub or Bitbucket — without the operational overhead of self-hosting a Git server.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Private Git hosting** | Fully managed, unlimited private repositories |
| **IAM access control** | Fine-grained `reader`, `writer`, and `admin` roles per project |
| **Mirroring** | Mirror from GitHub or Bitbucket (read-only sync) |
| **Cloud Build integration** | Trigger builds on push events from any branch or tag |
| **Audit logging** | All access and write events captured in Cloud Audit Logs |
| **gcloud CLI access** | Clone and push via `gcloud source repos clone` |

---

## Core Concepts

### Repository

```hcl
resource "google_sourcerepo_repository" "app_repo" {
  name    = "my-app-repo"
  project = var.project_id
}
```

### Mirror from GitHub

```hcl
resource "google_sourcerepo_repository" "github_mirror" {
  name    = "my-app-github-mirror"
  project = var.project_id

  pubsub_configs {
    topic                 = google_pubsub_topic.repo_events.id
    message_format        = "JSON"
    service_account_email = google_service_account.pubsub_sa.email
  }
}
```

> **Note**: GitHub and Bitbucket mirroring is configured via the Console or `gcloud` — the Terraform resource creates the repository entry, but the upstream mirror connection must be set via the UI or REST API. The `google_sourcerepo_repository` resource will import and preserve mirror settings once set.

### IAM Bindings

```hcl
# Grant a CI service account write access
resource "google_sourcerepo_repository_iam_member" "ci_writer" {
  project    = var.project_id
  repository = google_sourcerepo_repository.app_repo.name
  role       = "roles/source.writer"
  member     = "serviceAccount:${google_service_account.ci_sa.email}"
}

# Grant a developer team read access
resource "google_sourcerepo_repository_iam_member" "dev_reader" {
  project    = var.project_id
  repository = google_sourcerepo_repository.app_repo.name
  role       = "roles/source.reader"
  member     = "group:dev-team@example.com"
}
```

### Cloud Build Trigger Integration

```hcl
resource "google_cloudbuild_trigger" "csr_push_trigger" {
  name    = "build-on-main-push"
  project = var.project_id

  trigger_template {
    repo_name   = google_sourcerepo_repository.app_repo.name
    branch_name = "^main$"
  }

  filename = "cloudbuild.yaml"   # path to build config inside the repo
}
```

### Pub/Sub Notifications

```hcl
resource "google_pubsub_topic" "repo_events" {
  name    = "csr-repo-events"
  project = var.project_id
}

resource "google_sourcerepo_repository" "app_repo_with_pubsub" {
  name    = "my-app-repo"
  project = var.project_id

  pubsub_configs {
    topic                 = google_pubsub_topic.repo_events.id
    message_format        = "JSON"
    service_account_email = google_service_account.pubsub_sa.email
  }
}
```

### IAM Roles Reference

| Role | Description |
|------|-------------|
| `roles/source.reader` | Read-only access to repository contents and history |
| `roles/source.writer` | Push commits, create/delete branches and tags |
| `roles/source.admin` | Full control — manage IAM, delete repository |
| `roles/viewer` | View repository list only (project-level) |

### Cloning via gcloud

```bash
# Authenticate
gcloud auth login

# Clone a repository
gcloud source repos clone my-app-repo --project=my-project-id

# List all repositories in a project
gcloud source repos list --project=my-project-id
```

### Enable the API

```hcl
resource "google_project_service" "source_repo" {
  project            = var.project_id
  service            = "sourcerepo.googleapis.com"
  disable_on_destroy = false
}
```

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_sourcerepo_repository` | Create a private Git repository; configure Pub/Sub notifications |
| `google_sourcerepo_repository_iam_member` | Bind a member to `source.reader`, `source.writer`, or `source.admin` |
| `google_sourcerepo_repository_iam_binding` | Set the full IAM binding for a role on a repository |
| `google_sourcerepo_repository_iam_policy` | Apply a complete IAM policy to a repository |

---

## Security Guidance

- Use **`roles/source.reader`** for automated deployment pipelines — no write access is needed to read source for deployments.
- Prefer **group bindings** over individual user bindings for developer access — simplifies onboarding and offboarding.
- Enable **Cloud Audit Logs** (`DATA_READ` and `DATA_WRITE`) for `sourcerepo.googleapis.com` to capture every clone, push, and access event.
- For external mirroring (GitHub/Bitbucket), rotate the OAuth or SSH credentials regularly and store them in **Secret Manager**.
- Avoid using the default Compute Engine service account for CI — create a dedicated SA with only `roles/source.reader` or `roles/source.writer`.
- Apply **VPC Service Controls** perimeters if storing sensitive code — prevents data exfiltration via `git clone` from outside trusted networks.

---

## Related Docs

- [Cloud Source Repositories Overview](https://cloud.google.com/source-repositories/docs/overview)
- [Mirror a GitHub Repository](https://cloud.google.com/source-repositories/docs/mirroring-a-github-repository)
- [Cloud Build Integration](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers)
- [IAM Roles for Source Repositories](https://cloud.google.com/source-repositories/docs/access-control)
- [Pricing](https://cloud.google.com/source-repositories/pricing)
- [google_sourcerepo_repository](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sourcerepo_repository)
- [google_sourcerepo_repository_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sourcerepo_repository_iam)
