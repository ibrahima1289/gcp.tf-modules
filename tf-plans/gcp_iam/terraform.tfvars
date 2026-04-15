project_id = "your-project-id"

tags = {
  environment = "dev"
  team        = "platform"
}

# ---------------------------------------------------------------------------
# Example 1: CI/CD pipeline service account with project-level member binding
# ---------------------------------------------------------------------------
service_accounts = [
  {
    # Stable for_each key (never rename after first apply).
    key          = "cicd-pipeline-sa"
    account_id   = "cicd-pipeline-sa"
    display_name = "CI/CD Pipeline Service Account"
    description  = "Used by GitHub Actions OIDC federation to deploy Terraform"
    create       = true
  },
  {
    key          = "app-backend-sa"
    account_id   = "app-backend-sa"
    display_name = "Application Backend Service Account"
    description  = "Service account for the backend application workload"
    create       = false
  }
]

custom_roles = [
  {
    # Custom role with least-privilege permissions for the CI/CD pipeline.
    key         = "terraform-deployer-role"
    role_id     = "terraformDeployer"
    title       = "Terraform Deployer"
    description = "Least-privilege role for the Terraform CI/CD deployment service account"
    permissions = [
      "compute.networks.get",
      "compute.subnetworks.get",
      "compute.routers.get",
      "iam.serviceAccounts.get",
      "iam.serviceAccounts.list",
      "resourcemanager.projects.getIamPolicy"
    ]
    scope  = "project"
    stage  = "GA"
    create = true
  }
]

# WARNING: Authoritative bindings replace ALL existing members for the role on the target resource.
# Any principals not listed here will have the role REMOVED on next apply.
# Use 'members' (additive) when multiple configurations share the same role on a resource.
bindings = [
  {
    key      = "logging-viewer"
    scope    = "project"
    resource = "your-project-id"
    role     = "roles/logging.viewer"
    members = [
      "serviceAccount:app-backend-sa@your-project-id.iam.gserviceaccount.com",
      "group:ops-team@example.com"
    ]
    create = false
  }
]

# ---------------------------------------------------------------------------
# Example 2: Cross-scope additive members (project + folder)
# ---------------------------------------------------------------------------
members = [
  {
    # Grant the CI/CD pipeline SA storage admin rights on this project (additive — safe to share).
    key      = "cicd-storage-admin"
    scope    = "project"
    resource = "your-project-id"
    role     = "roles/storage.objectAdmin"
    member   = "serviceAccount:cicd-pipeline-sa@your-project-id.iam.gserviceaccount.com"
    create   = true
  },
  {
    # Grant a user viewer rights on the parent folder (additive).
    key      = "folder-viewer-alice"
    scope    = "folder"
    resource = "123456789012"
    role     = "roles/viewer"
    member   = "user:alice@example.com"
    create   = false
  },
  {
    # Grant the backend SA Pub/Sub publisher rights (additive).
    key      = "backend-pubsub-publisher"
    scope    = "project"
    resource = "your-project-id"
    role     = "roles/pubsub.publisher"
    member   = "serviceAccount:app-backend-sa@your-project-id.iam.gserviceaccount.com"
    create   = false
  }
]
