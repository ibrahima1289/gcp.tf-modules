# ---------------------------------------------------------------------------
# Provider region
# ---------------------------------------------------------------------------
region = "us-central1"

# ---------------------------------------------------------------------------
# Common labels applied to all projects
# ---------------------------------------------------------------------------
labels = {
  owner       = "platform-team"
  environment = "shared"
}

# ---------------------------------------------------------------------------
# Protect projects from accidental deletion
# ---------------------------------------------------------------------------
prevent_destroy = true

# ---------------------------------------------------------------------------
# One or many projects
# Each item must set exactly one of org_id or folder_id
# ---------------------------------------------------------------------------
projects = [
  {
    project_id      = "example-proj-dev1"
    name            = "Example Project Dev"
    billing_account = "000000-000000-000000"
    org_id          = "123456789012"
    enable_services = [
      "compute.googleapis.com",
      "storage.googleapis.com"
    ]
    labels = {
      tier = "dev"
    }
  },
  {
    project_id      = "example-proj-prod1"
    name            = "Example Project Prod"
    billing_account = "000000-000000-000000"
    folder_id       = "987654321098"
    enable_services = [
      "compute.googleapis.com",
      "container.googleapis.com"
    ]
    labels = {
      tier = "prod"
    }
  },
  {
    project_id      = "example-proj-prod2"
    name            = "Example Project Prod 2"
    billing_account = "000000-000000-000000"
    enable_services = [
      "compute.googleapis.com",
      "container.googleapis.com"
    ]
    labels = {
      tier = "prod"
      team = "payments"
    }
  }
]
