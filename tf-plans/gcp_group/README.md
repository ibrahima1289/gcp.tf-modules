# GCP Cloud Identity Groups Deployment Plan

Wrapper configuration for the [GCP Cloud Identity Groups module](../../modules/security/gcp_group/README.md). Deploys one or many Cloud Identity groups with memberships for IAM-at-scale, workforce identity governance, and access management.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_group/
├── providers.tf         → Terraform version constraints, GCS backend (optional), google provider
├── variables.tf         → Input variables mirroring the module interface
├── locals.tf            → created_date timestamp
├── main.tf              → Module call with merged tags
├── outputs.tf           → Pass-through outputs from the module
└── terraform.tfvars     → Example values (2 groups with memberships)

      ↓ calls

modules/security/gcp_group/
├── variables.tf         → Full variable definitions with validations
├── locals.tf            → groups_map, memberships_map, parent path resolution
├── main.tf              → google_cloud_identity_group + google_cloud_identity_group_membership
├── outputs.tf           → All group and membership outputs
└── providers.tf         → Version constraints only
```

---

## Requirements

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |
| Cloud Identity or Google Workspace tenant | — |
| IAM role: [`roles/cloudidentity.groups.admin`](https://cloud.google.com/identity/docs/how-to/setup) on the customer | — |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `customer_id` | `string` | Cloud Identity customer ID (e.g. `C0xxxxxxx`). Found via `gcloud organizations list`. |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Governance metadata exposed in module outputs. |
| `groups` | `list(object)` | `[]` | One or many group definitions. See [module README](../../modules/security/gcp_group/README.md#groups-object-fields) for full field reference. |

---

## Outputs

| Output | Description |
|--------|-------------|
| `group_ids` | Group resource names keyed by group key. |
| `group_names` | Group display names keyed by group key. |
| `group_emails` | Group email addresses keyed by group key. |
| `membership_ids` | Membership resource names keyed by composite key. |
| `membership_group_keys` | Parent group key per membership. |
| `membership_member_emails` | Member email per membership. |
| `customer_parent` | Resolved Cloud Identity parent path. |
| `common_tags` | Governance metadata for this module call. |

---

## Apply Workflow

### 1. Authenticate

```bash
# Application Default Credentials (recommended for local dev)
gcloud auth application-default login

# Ensure Cloud Identity API is enabled
gcloud services enable cloudidentity.googleapis.com --project=my-project
```

### 2. Find your customer ID

```bash
gcloud organizations list
# Look for directoryCustomerId in the output
```

### 3. Configure variables

Edit `terraform.tfvars` with your customer ID and group definitions:

```hcl
customer_id = "C0xxxxxxx"

tags = {
  owner       = "platform-team"
  environment = "production"
}

groups = [
  {
    key          = "platform-engineers"
    email        = "platform-engineers@example.com"
    display_name = "Platform Engineers"
    labels       = { "cloudidentity.googleapis.com/groups.security" = "" }

    members = [
      { key = "alice", member_email = "alice@example.com", roles = ["MEMBER"] }
    ]
  }
]
```

### 4. (Optional) Enable remote state

Uncomment the GCS backend block in `providers.tf`:

```hcl
backend "gcs" {
  bucket = "my-terraform-state-bucket"
  prefix = "gcp-group"
}
```

### 5. Initialize and plan

```bash
cd tf-plans/gcp_group
terraform init
terraform plan -out=tfplan
```

### 6. Apply

```bash
terraform apply tfplan
```

### 7. Inspect outputs

```bash
terraform output group_emails
terraform output membership_ids
```

---

## Example Configurations

### Security group for IAM bindings

```hcl
{
  key          = "infra-admins"
  email        = "infra-admins@example.com"
  display_name = "Infrastructure Admins"
  labels       = { "cloudidentity.googleapis.com/groups.security" = "" }

  members = [
    { key = "alice", member_email = "alice@example.com", roles = ["MEMBER"] },
    { key = "bob",   member_email = "bob@example.com",   roles = ["OWNER"] }
  ]
}
```

### Nested group (group as member of another group)

```hcl
# Parent group
{
  key   = "all-engineers"
  email = "all-engineers@example.com"
  labels = { "cloudidentity.googleapis.com/groups.security" = "" }

  members = [
    # Add a sub-group as a member
    { key = "platform-sub", member_email = "platform-engineers@example.com", roles = ["MEMBER"] }
  ]
}
```

### Group with selective membership creation (`create = false`)

```hcl
{
  key    = "read-only-users"
  email  = "read-only-users@example.com"
  labels = { "cloudidentity.googleapis.com/groups.security" = "" }

  members = [
    { key = "alice", member_email = "alice@example.com", roles = ["MEMBER"], create = true  },
    { key = "bob",   member_email = "bob@example.com",   roles = ["MEMBER"], create = false }
  ]
}
```

---

## Related Docs

- [Cloud Identity Groups Module](../../modules/security/gcp_group/README.md)
- [Cloud Identity Groups Service Explainer](../../modules/security/gcp_group/gcp-group.md)
- [GCP IAM Module](../../modules/security/gcp_iam/README.md)
- [Cloud Identity Groups Pricing](https://cloud.google.com/identity/pricing)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Terraform Deployment Guide](../../gcp-terraform-deployment-cli-github-actions.md)
- [Release Notes](../../RELEASE.md)
