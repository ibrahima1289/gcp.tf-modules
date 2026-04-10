# GCP Organization — Terraform Deployment Plan

This deployment plan (`tf-plans/gcp_organization`) is a ready-to-use Terraform wrapper that calls the reusable [organization module](../../modules/hierarchy/organization/README.md) to manage Google Cloud Organization-level resources.

---

## Architecture

```
tf-plans/gcp_organization
        │
        └─► modules/hierarchy/organization
                    │
                    ├─ data.google_organization          (lookup — cannot create)
                    ├─ google_organization_iam_member    (additive role grants)
                    ├─ google_org_policy_policy          (OrgPolicy v2 constraints)
                    ├─ google_logging_organization_sink  (org-wide log export)
                    └─ google_essential_contacts_contact (notification contacts)
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.5 |
| Google Provider | >= 6.0 |
| Caller permissions | `roles/resourcemanager.organizationAdmin` or equivalent |
| Authentication | Application Default Credentials **or** Workload Identity Federation |
| GCS bucket (optional) | For remote state backend |

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Copy and edit variable values
cp terraform.tfvars terraform.tfvars.local   # optional — keep secrets out of VCS

# 3. Initialise
terraform init

# 4. Validate syntax
terraform validate

# 5. Review execution plan
terraform plan -var-file="terraform.tfvars"

# 6. Apply
terraform apply -var-file="terraform.tfvars"
```

> **Remote state:** Uncomment the `backend "gcs"` block in `providers.tf` and update the bucket/prefix before running `terraform init` in a shared environment.

---

## Files

| File | Purpose |
|---|---|
| `main.tf` | Calls the organization module with all input variables |
| `locals.tf` | Computes `created_date` stamp merged into labels |
| `variables.tf` | All input variable declarations mirroring the module |
| `outputs.tf` | Pass-through outputs from the module |
| `providers.tf` | Terraform version constraint and Google provider config |
| `terraform.tfvars` | Example/default variable values — edit before applying |

---

## Variables

### Required — supply one of `org_domain` or `org_id`

| Variable | Type | Description |
|---|---|---|
| `org_domain` | `string` | Primary domain of the GCP Organization (e.g., `example.com`) |
| `org_id` | `string` | Numeric Organization ID (e.g., `123456789012`) |

### Optional

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-central1` | Default region for the Google provider |
| `labels` | `map(string)` | `{}` | Common labels merged with `created_date` and `managed_by=terraform` |
| `iam_members` | `list(object)` | `[]` | Additive org-level IAM role grants |
| `org_policies` | `list(object)` | `[]` | OrgPolicy v2 boolean/list constraints |
| `log_sinks` | `list(object)` | `[]` | Organization-wide log export sinks |
| `essential_contacts` | `list(object)` | `[]` | Notification contacts at the org level |

---

## Outputs

| Output | Description |
|---|---|
| `org_id` | Numeric Organization ID |
| `org_name` | Organization display name |
| `org_resource_name` | Full resource name (`organizations/<org_id>`) |
| `iam_member_ids` | Map of IAM member key → resource ID |
| `org_policy_names` | Map of org policy key → resource name |
| `log_sink_names` | Map of log sink key → sink name |
| `log_sink_writer_identities` | Map of log sink key → writer identity (grant this write access to the destination) |
| `essential_contact_ids` | Map of essential contact key → contact resource ID |

---

## Log Sink — Writer Identity

When a log sink is created, GCP generates a unique **writer identity** service account. You must grant this identity write access to the sink destination before log routing will work:

```hcl
# Example — grant the sink writer identity access to a GCS bucket
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = "my-org-audit-logs"
  role   = "roles/storage.objectCreator"
  member = module.organization.log_sink_writer_identities["audit-sink"]
}
```

---

## Example — `terraform.tfvars`

```hcl
org_domain = "example.com"
region     = "us-central1"

labels = {
  environment = "platform"
  owner       = "cloud-team"
}

iam_members = [
  {
    key    = "org-admin-group"
    role   = "roles/viewer"
    member = "group:gcp-org-admins@example.com"
  }
]

org_policies = [
  {
    key        = "disable-serial-port"
    constraint = "compute.disableSerialPortAccess"
    type       = "boolean"
    enforce    = "TRUE"
  }
]
```

---

## Related Docs

- [Organization Module README](../../modules/hierarchy/organization/README.md)
- [Folder Module README](../../modules/hierarchy/folder/README.md)
- [Folder Deployment Plan](../gcp_folder/README.md)
- [GCP Module Service List](../../gcp-module-service-list.md)
- [GCP Services Pricing Guide](../../gcp-services-pricing-guide.md)
- [Terraform Deployment Guide (CLI & GitHub Actions)](../../gcp-terraform-deployment-cli-github-actions.md)
