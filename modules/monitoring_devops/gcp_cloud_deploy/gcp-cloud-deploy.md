# Google Cloud Deploy

[Cloud Deploy](https://cloud.google.com/deploy/docs) is a fully managed continuous delivery service that automates deployments to a sequence of targets (dev → staging → production) with built-in approval gates, rollback, canary, and blue/green strategies. It integrates with Cloud Build for CI and manages release promotion across GKE, Cloud Run, Anthos, and GKE Enterprise targets.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

| Capability | Description |
|------------|-------------|
| **Delivery pipelines** | Ordered sequence of stages (targets) that releases progress through |
| **Targets** | A deployment destination: GKE cluster, Cloud Run service, Anthos fleet |
| **Releases** | An immutable snapshot of the artifacts and configs to be deployed |
| **Rollouts** | A deployment of a release to a specific target |
| **Approval gates** | Manual approval required before promoting to a specific stage |
| **Rollback** | One-click rollback to any previous successful release |
| **Canary deployments** | Route a percentage of traffic to the new version before full rollout |
| **Blue/green deployments** | Full deployment to an idle environment; switch traffic on approval |
| **Skaffold integration** | Uses Skaffold to render and apply manifests |

---

## Core Concepts

### Pipeline Structure

```text
Delivery Pipeline
  ├── Stage 1: dev      → Target: gke-dev-cluster
  ├── Stage 2: staging  → Target: gke-staging-cluster   [requires approval]
  └── Stage 3: prod     → Target: gke-prod-cluster      [requires approval]
```

### Delivery Pipeline

```hcl
resource "google_clouddeploy_delivery_pipeline" "app_pipeline" {
  name        = "my-app-pipeline"
  location    = "us-central1"
  project     = var.project_id
  description = "My application delivery pipeline"

  serial_pipeline {
    stages {
      target_id = google_clouddeploy_target.dev.name
      profiles  = ["dev"]
    }
    stages {
      target_id = google_clouddeploy_target.staging.name
      profiles  = ["staging"]
      strategy {
        canary {
          runtime_config {
            cloud_run {
              automatic_traffic_control = true
            }
          }
          canary_deployment {
            percentages = [25, 50, 75]
          }
        }
      }
    }
    stages {
      target_id = google_clouddeploy_target.prod.name
      profiles  = ["prod"]
      deploy_parameters {
        values = { "replicas" = "10" }
      }
    }
  }
}
```

### Targets

```hcl
# GKE target
resource "google_clouddeploy_target" "dev" {
  name     = "gke-dev"
  location = "us-central1"
  project  = var.project_id

  gke {
    cluster = "projects/${var.project_id}/locations/us-central1/clusters/dev-cluster"
  }

  execution_configs {
    usages          = ["RENDER", "DEPLOY"]
    service_account = google_service_account.deploy_sa.email
  }
}

# Cloud Run target
resource "google_clouddeploy_target" "staging" {
  name     = "cloudrun-staging"
  location = "us-central1"
  project  = var.project_id

  run {
    location = "projects/${var.project_id}/locations/us-central1"
  }

  require_approval = true   # manual gate before deploying to staging
}

# Multi-target (deploy to multiple targets simultaneously)
resource "google_clouddeploy_target" "prod" {
  name     = "multi-prod"
  location = "us-central1"
  project  = var.project_id

  multi_target {
    target_ids = [
      google_clouddeploy_target.prod_us.name,
      google_clouddeploy_target.prod_eu.name,
    ]
  }

  require_approval = true
}
```

### Automation Rules

```hcl
resource "google_clouddeploy_automation" "auto_promote" {
  name              = "auto-promote-dev-to-staging"
  location          = "us-central1"
  project           = var.project_id
  delivery_pipeline = google_clouddeploy_delivery_pipeline.app_pipeline.name
  service_account   = google_service_account.deploy_sa.email

  rules {
    promote_release_rule {
      id                    = "auto-promote"
      wait                  = "3600s"   # wait 1h after successful dev deploy
      destination_target_id = "@next"   # next stage in the pipeline
    }
  }
}

resource "google_clouddeploy_automation" "auto_rollback" {
  name              = "auto-rollback-on-failure"
  location          = "us-central1"
  project           = var.project_id
  delivery_pipeline = google_clouddeploy_delivery_pipeline.app_pipeline.name
  service_account   = google_service_account.deploy_sa.email

  rules {
    repair_rollout_rule {
      id      = "rollback-on-failure"
      phases  = ["DEPLOY"]
      jobs    = ["deploy-job"]
      repair_phases {
        rollback {}
      }
    }
  }
}
```

### Service Account and IAM

```hcl
resource "google_service_account" "deploy_sa" {
  account_id   = "cloud-deploy-sa"
  display_name = "Cloud Deploy Service Account"
}

# Allow Cloud Deploy SA to deploy to GKE
resource "google_project_iam_member" "gke_deploy" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.deploy_sa.email}"
}

# Allow Cloud Deploy SA to deploy Cloud Run services
resource "google_project_iam_member" "run_deploy" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deploy_sa.email}"
}

# Allow Cloud Deploy SA to read from Artifact Registry
resource "google_project_iam_member" "ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.deploy_sa.email}"
}

# Allow Cloud Deploy to act as the SA
resource "google_service_account_iam_member" "deploy_act_as" {
  service_account_id = google_service_account.deploy_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}
```

### Deployment Strategies

| Strategy | Description | Targets |
|----------|-------------|---------|
| **Standard** | Full replacement of all instances at once | GKE, Cloud Run |
| **Canary** | Gradual traffic shift (e.g., 25% → 50% → 75% → 100%) | Cloud Run, GKE |
| **Blue/green** | Full deployment to idle environment; switch on approval | Cloud Run, GKE |

---

## Terraform Resources

| Resource | Purpose |
|----------|---------|
| `google_clouddeploy_delivery_pipeline` | Define the ordered sequence of deployment stages |
| `google_clouddeploy_target` | Define a deployment destination (GKE, Cloud Run, Anthos) |
| `google_clouddeploy_automation` | Automate promote-on-success and rollback-on-failure rules |
| `google_clouddeploy_custom_target_type` | Define custom deployment targets |

---

## Security Guidance

- Use **separate service accounts** per environment target with least-privilege roles — never share a prod deploy SA with dev.
- Enable **approval gates** (`require_approval = true`) on staging and production targets; require two approvers for production.
- Use **automation rollback rules** to automatically roll back failed deployments rather than relying on manual intervention.
- Restrict `roles/clouddeploy.releaseCreator` to CI pipelines only — developers should not create releases manually.
- Enable **Cloud Audit Logs** for `clouddeploy.googleapis.com` to track all release creation and promotion events.
- Store Skaffold configs and deployment manifests in version control; never mutate a release after creation (releases are immutable).

---

## Related Docs

- [Cloud Deploy Overview](https://cloud.google.com/deploy/docs/overview)
- [Delivery Pipelines](https://cloud.google.com/deploy/docs/create-pipeline-targets)
- [Deployment Strategies](https://cloud.google.com/deploy/docs/deployment-strategies)
- [Automations](https://cloud.google.com/deploy/docs/automation)
- [Pricing](https://cloud.google.com/deploy/pricing)
- [google_clouddeploy_delivery_pipeline](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_delivery_pipeline)
- [google_clouddeploy_target](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target)
- [google_clouddeploy_automation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_automation)
