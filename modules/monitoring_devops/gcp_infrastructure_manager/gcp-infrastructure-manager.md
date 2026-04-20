# Infrastructure Manager

[Infrastructure Manager](https://cloud.google.com/infrastructure-manager/docs) is a fully managed Google Cloud service that provisions and manages infrastructure using Terraform configurations stored in Cloud Storage or a Git repository. It handles the Terraform execution environment, state file storage, and deployment lifecycle — eliminating the need to run and secure your own Terraform pipeline.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Managed Terraform execution** | GCP runs `terraform init`, `plan`, and `apply` on your behalf |
| **State management** | Terraform state stored in a managed GCS bucket — no backend configuration needed |
| **Git & GCS sources** | Configs sourced from a Cloud Storage path or a Git repo (Cloud Source Repositories, GitHub, GitLab) |
| **Preview mode** | Run `terraform plan` without applying — results stored for review |
| **Deployment lifecycle** | Track CREATING → ACTIVE → UPDATING → DELETING states |
| **Terraform version selection** | Pin the Terraform version per deployment |
| **Quota-locked revisions** | Immutable revision history for every apply |
| **Drift detection** | Detect out-of-band changes between the active revision and real infrastructure |

---

## Core Concepts

### Deployment Lifecycle

```text
CREATING  → Configuration fetched, plan run
    ↓
ACTIVE    → Resources provisioned and healthy
    ↓
UPDATING  → A new revision is being applied
    ↓
FAILED    → Apply failed; previous revision remains active
    ↓
DELETING  → terraform destroy running
```

### Deployment Resource

```hcl
resource "google_infra_manager_deployment" "app_infra" {
  deployment_id = "app-infra-prod"
  location      = "us-central1"
  project       = var.project_id

  # Use a Cloud Storage path as the Terraform root module source
  terraform_blueprint {
    gcs_source = "gs://${google_storage_bucket.tf_configs.name}/modules/app/"

    # Pin the Terraform version
    deployment_input {
      root_module_uri = "gs://${google_storage_bucket.tf_configs.name}/modules/app/"

      input_values {
        name = "project_id"
        value = jsonencode(var.project_id)
      }
      input_values {
        name = "region"
        value = jsonencode("us-central1")
      }
    }
  }

  service_account = google_service_account.infra_manager_sa.email

  labels = {
    env     = "prod"
    team    = "platform"
    managed = "infra-manager"
  }
}
```

### Git-Backed Deployment

```hcl
resource "google_infra_manager_deployment" "git_backed" {
  deployment_id = "git-backed-infra"
  location      = "us-central1"
  project       = var.project_id

  terraform_blueprint {
    git_source {
      repo      = "https://github.com/my-org/infra-repo.git"
      directory = "environments/prod"
      ref       = "refs/heads/main"
    }
  }

  service_account = google_service_account.infra_manager_sa.email
}
```

### Preview (Plan Only)

```hcl
resource "google_infra_manager_preview" "plan_preview" {
  preview_id    = "app-infra-preview"
  location      = "us-central1"
  project       = var.project_id
  deployment    = google_infra_manager_deployment.app_infra.deployment_id

  terraform_blueprint {
    gcs_source = "gs://${google_storage_bucket.tf_configs.name}/modules/app/"
  }

  service_account = google_service_account.infra_manager_sa.email
  preview_mode    = "DEFAULT"   # DEFAULT = plan; LOCK_AND_PREVIEW = lock deployment before planning
}
```

### Service Account and IAM

```hcl
resource "google_service_account" "infra_manager_sa" {
  account_id   = "infra-manager-sa"
  display_name = "Infrastructure Manager Service Account"
}

# The SA must have all permissions needed to create the managed resources
resource "google_project_iam_member" "infra_manager_editor" {
  project = var.project_id
  role    = "roles/editor"   # scope down to only what your Terraform configs require
  member  = "serviceAccount:${google_service_account.infra_manager_sa.email}"
}

# Allow the Infrastructure Manager service to act as this SA
resource "google_service_account_iam_member" "infra_manager_act_as" {
  service_account_id = google_service_account.infra_manager_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.project_number}@cloudservices.gserviceaccount.com"
}

# Grant caller permission to manage deployments
resource "google_project_iam_member" "deploy_admin" {
  project = var.project_id
  role    = "roles/config.admin"
  member  = "serviceAccount:${var.cicd_sa}"
}
```

### GCS Config Bucket

```hcl
resource "google_storage_bucket" "tf_configs" {
  name                        = "${var.project_id}-tf-configs"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

# Grant Infrastructure Manager read access to configs
resource "google_storage_bucket_iam_member" "infra_manager_gcs_reader" {
  bucket = google_storage_bucket.tf_configs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.infra_manager_sa.email}"
}
```

### IAM Roles Reference

| Role | Description |
|------|-------------|
| `roles/config.admin` | Full access to deployments, previews, and revisions |
| `roles/config.editor` | Create and update deployments; cannot delete |
| `roles/config.viewer` | Read-only access to deployments and revision history |
| `roles/config.agent` | Used internally by the Infrastructure Manager service agent |

### Enable the API

```hcl
resource "google_project_service" "infra_manager" {
  project            = var.project_id
  service            = "config.googleapis.com"
  disable_on_destroy = false
}
```

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_infra_manager_deployment` | Create and manage an Infrastructure Manager deployment (full apply lifecycle) |
| `google_infra_manager_preview` | Run a Terraform plan without applying; review proposed changes |

---

## Security Guidance

- Apply the **principle of least privilege** to the deployment service account — avoid `roles/editor` or `roles/owner`; enumerate only the roles needed by your configs.
- Use **VPC Service Controls** to restrict the Infrastructure Manager API to trusted networks and prevent exfiltration of Terraform state.
- Enable **Cloud Audit Logs** (`DATA_WRITE`) for `config.googleapis.com` to record every deployment create, update, and delete.
- Store Terraform configs in a **versioned GCS bucket** or a protected Git branch — require PR approvals before merging changes that will be automatically applied.
- Use **preview mode** as a required step in CI before promoting a change to `ACTIVE`; treat the plan output as a required review artifact.
- Never embed secrets in Terraform variable inputs — pass sensitive values via `google_secret_manager_secret_version` data sources inside your configs.

---

## Related Docs

- [Infrastructure Manager Overview](https://cloud.google.com/infrastructure-manager/docs/overview)
- [Create a Deployment](https://cloud.google.com/infrastructure-manager/docs/create-deployment)
- [Deployment Lifecycle States](https://cloud.google.com/infrastructure-manager/docs/deployment-states)
- [Preview Changes](https://cloud.google.com/infrastructure-manager/docs/preview-deployment)
- [IAM Roles](https://cloud.google.com/infrastructure-manager/docs/access-control)
- [Pricing](https://cloud.google.com/infrastructure-manager/pricing)
- [google_infra_manager_deployment](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/infra_manager_deployment)
- [google_infra_manager_preview](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/infra_manager_preview)
