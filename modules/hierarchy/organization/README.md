# GCP Organization Terraform Module

Manages [Google Cloud Organization](https://cloud.google.com/resource-manager/docs/creating-managing-organization) governance resources: IAM member grants, OrgPolicy v2 constraints, organization-level log sinks, and essential contacts.

> **Note:** Google Cloud Organizations cannot be created via Terraform. The organization node is provisioned through Google Workspace or Cloud Identity outside of this automation. This module looks up an existing organization and manages resources within it.

---

## Architecture

```text
+--------------------------------------------------+
|  Google Cloud Organization (data source lookup)  |
|  domain: example.com  or  org_id: 123456789012   |
+--------------------------------------------------+
           |
           +------------------------------------------+
           |                   |                      |
           v                   v                      v
+---------------------+ +--------------+ +--------------------+
| IAM Members         | | Org Policies | | Log Sinks          |
| (additive grants)   | | (v2 API)     | | (GCS/BQ/Pub-Sub)   |
+---------------------+ +--------------+ +--------------------+
| roles/viewer        | | boolean:     | | include_children   |
| roles/orgAdmin      | |  enforce     | | filter expression  |
| roles/securityAdmin | | list:        | | writer_identity    |
+---------------------+ |  allow_all   | +--------------------+
                        |  deny_all    |
                        |  values{}    | +--------------------+
                        +--------------+ | Essential Contacts |
                                        | BILLING, SECURITY  |
                                        | LEGAL, TECHNICAL   |
                                        +--------------------+
```

---

## Required Variables

| Name | Type | Description |
|------|------|-------------|
| `org_domain` **or** `org_id` | `string` | Provide exactly one: primary domain (e.g., `example.com`) **or** numeric org ID (e.g., `123456789012`). |

---

## Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Region passed to the Google provider. Org-level resources are global. |
| `iam_members` | `list(object)` | `[]` | Additive IAM grants: `key`, `role`, `member`. Uses `google_organization_iam_member` (non-destructive). |
| `org_policies` | `list(object)` | `[]` | OrgPolicy v2 constraints: `key`, `constraint`, `type` (boolean/list), `enforce`, `allow_all`, `deny_all`, `allowed_values`, `denied_values`. |
| `log_sinks` | `list(object)` | `[]` | Org-wide log sinks: `key`, `name`, `destination`, `filter`, `include_children`. |
| `essential_contacts` | `list(object)` | `[]` | Notification contacts: `key`, `email`, `language_tag`, `notification_categories`. |
| `labels` | `map(string)` | `{}` | Common labels stored in locals for reference (org resources do not support labels directly). |

---

## Outputs

| Name | Description |
|------|-------------|
| `org_id` | Numeric Google Cloud Organization ID. |
| `org_name` | Display name of the organization. |
| `org_resource_name` | Full resource name (`organizations/<org_id>`). |
| `iam_member_ids` | Map of IAM member key → resource ID. |
| `org_policy_names` | Map of org policy key → resource name. |
| `log_sink_names` | Map of log sink key → sink name. |
| `log_sink_writer_identities` | Map of log sink key → writer identity. Grant this identity write access to the sink destination. |
| `essential_contact_ids` | Map of essential contact key → contact resource ID. |

---

## Usage

```hcl
module "organization" {
  source = "../../modules/hierarchy/organization"

  # Look up the org by domain.
  org_domain = "example.com"
  region     = "us-central1"

  labels = {
    environment = "platform"
    managed_by  = "terraform"
  }

  # Additive IAM grants at the org level.
  iam_members = [
    {
      key    = "org-viewer-security-group"
      role   = "roles/viewer"
      member = "group:gcp-org-admins@example.com"
    }
  ]

  # Boolean org policy: disable VM serial port access.
  org_policies = [
    {
      key        = "disable-serial-port"
      constraint = "compute.disableSerialPortAccess"
      type       = "boolean"
      enforce    = "TRUE"
    }
  ]

  # Route all audit logs to a GCS bucket.
  log_sinks = [
    {
      key              = "audit-sink"
      name             = "org-audit-log-sink"
      destination      = "storage.googleapis.com/my-org-audit-logs"
      filter           = "logName:\"cloudaudit.googleapis.com\""
      include_children = true
    }
  ]

  # Security team essential contact.
  essential_contacts = [
    {
      key                     = "security-team"
      email                   = "security@example.com"
      language_tag            = "en"
      notification_categories = ["SECURITY", "TECHNICAL"]
    }
  ]
}

# Grant the log sink's writer identity write access to the destination bucket.
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = "my-org-audit-logs"
  role   = "roles/storage.objectCreator"
  member = module.organization.log_sink_writer_identities["audit-sink"]
}
```

---

## Notes

- **Organization creation**: Organizations are created outside Terraform via [Google Workspace](https://workspace.google.com/) or [Cloud Identity](https://cloud.google.com/identity). This module manages resources *within* an existing organization.
- **IAM safety**: `google_organization_iam_member` (additive) is used rather than `google_organization_iam_binding` (authoritative per role) to avoid removing unmanaged principals during apply.
- **Log sink destinations**: After creating a log sink, grant the `writer_identity` output write access to the destination (GCS `roles/storage.objectCreator`, BigQuery `roles/bigquery.dataEditor`, Pub/Sub `roles/pubsub.publisher`).
- **Required APIs**: Ensure `cloudresourcemanager.googleapis.com`, `essentialcontacts.googleapis.com`, `logging.googleapis.com`, and `orgpolicy.googleapis.com` are enabled on a project with org-level permissions.

---

## Related Docs

- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
