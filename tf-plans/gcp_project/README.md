# GCP Project Wrapper

This wrapper calls the reusable module at `modules/hierarchy/project` and supports creating one or many projects in a single plan.

## Inputs

- `region` (optional): Provider region. Default is `us-central1`.
- `labels` (optional): Common labels merged into every project.
- `prevent_destroy` (optional): Enables deletion protection lifecycle rule.
- `projects` (required for real use): List of project objects.

Each `projects` item supports:

- `project_id` (required)
- `name` (required)
- `billing_account` (optional)
- `org_id` (optional, exactly one of `org_id` or `folder_id`)
- `folder_id` (optional, exactly one of `org_id` or `folder_id`)
- `enable_services` (optional)
- `labels` (optional)

## Example

```hcl
region = "us-central1"

labels = {
  owner = "platform-team"
}

projects = [
  {
    project_id      = "sample-proj-dev1"
    name            = "Sample Project Dev"
    billing_account = "000000-000000-000000"
    org_id          = "123456789012"
    enable_services = ["compute.googleapis.com", "storage.googleapis.com"]
    labels = {
      environment = "dev"
    }
  },
  {
    project_id      = "sample-proj-prod1"
    name            = "Sample Project Prod"
    billing_account = "000000-000000-000000"
    folder_id       = "987654321098"
    enable_services = ["compute.googleapis.com"]
    labels = {
      environment = "prod"
    }
  }
]
```
