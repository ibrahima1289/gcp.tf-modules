# GCP Cloud Identity Groups Terraform Module

Reusable Terraform module for creating one or many [Google Cloud Identity Groups](https://cloud.google.com/identity/docs/groups) and their memberships. Groups are used as IAM principals (`group:name@domain.com`) to manage access at scale — bind a role to a group once, then control access by managing group membership.

> Part of [gcp.tf-modules](../../../README.md) · [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Architecture

```text
module "gcp_group"
├── google_cloud_identity_group.group             (one per groups[] entry, create = true)
│   ├── group_key {}                               (email as canonical identifier)
│   ├── labels {}                                  (group type classification)
│   └── display_name / description
└── google_cloud_identity_group_membership.membership  (one per members[] entry, create = true)
    ├── preferred_member_key {}                    (member email)
    └── dynamic roles {}                           (MEMBER / MANAGER / OWNER)
```

Data flow:

```text
var.groups[] + var.customer_id + var.tags
            ↓
locals.groups_map          ← filtered by create = true
locals.memberships_map     ← flattened groups × members, filtered by create = true
            ↓
google_cloud_identity_group.group[key]
            ↓
google_cloud_identity_group_membership.membership[group_key--member_key]
            ↓
Outputs: group_ids, group_emails, membership_ids
```

---

## Requirements

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |
| Cloud Identity or Google Workspace tenant | — |
| IAM role: [`roles/cloudidentity.groups.admin`](https://cloud.google.com/identity/docs/how-to/setup#auth-no-dwd) on the customer | — |

---

## Resources

| Resource | Purpose |
|----------|---------|
| [`google_cloud_identity_group`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | Creates a Cloud Identity group within the customer tenant |
| [`google_cloud_identity_group_membership`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | Adds a member (user, SA, or group) to a group with assigned roles |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `customer_id` | `string` | Cloud Identity customer ID (e.g. `C0xxxxxxx`). Found via `gcloud organizations list`. |
| `groups` | `list(object)` | One or many group definitions. See [`groups` object fields](#groups-object-fields). |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Governance metadata exposed in module outputs (`managed_by`, `created_date`). |

---

## `groups` Object Fields

### Core Identity

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable unique key for `for_each`. Must be unique across the list. |
| `email` | `string` | ✅ | — | Group email address used as the GroupKey identifier. |
| `display_name` | `string` | | `""` | Human-readable display name. |
| `description` | `string` | | `""` | Human-readable description. |
| `labels` | `map(string)` | | `{ "cloudidentity.googleapis.com/groups.discussion_forum" = "" }` | Group type labels. At least one label is required by the API. See [label reference](#group-type-labels). |
| `initial_group_config` | `string` | | `"EMPTY"` | `EMPTY`, `WITH_INITIAL_OWNER`, or `INITIAL_GROUP_CONFIG_UNSPECIFIED`. |
| `create` | `bool` | | `true` | Set `false` to skip creating this group while keeping the entry in config. |

### Group Type Labels

| Label Key | Group Type |
|-----------|-----------|
| `cloudidentity.googleapis.com/groups.discussion_forum` | General-purpose mailing list |
| `cloudidentity.googleapis.com/groups.security` | Security group (hardened governance, recommended for IAM) |
| `cloudidentity.googleapis.com/groups.dynamic` | Dynamic membership via CEL expression |
| `cloudidentity.googleapis.com/groups.transitive_member_all` | Enables transitive membership resolution |

> Security groups (`groups.security`) are the recommended type for any group used in IAM policy bindings.

### `members` Object Fields

Each item in `members` creates one `google_cloud_identity_group_membership`:

| Field | Type | Required | Default | Description |
|-------|------|:--------:|---------|-------------|
| `key` | `string` | ✅ | — | Stable unique key scoped to the parent group. |
| `member_email` | `string` | ✅ | — | Email of the user, service account, or nested group to add. |
| `roles` | `list(string)` | | `["MEMBER"]` | Roles within the group: `MEMBER`, `MANAGER`, `OWNER`. `MEMBER` is always required. |
| `create` | `bool` | | `true` | Set `false` to skip this membership while keeping it in config. |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `group_ids` | `map(string)` | Group resource names keyed by group key. |
| `group_names` | `map(string)` | Group display names keyed by group key. |
| `group_emails` | `map(string)` | Group email addresses keyed by group key. |
| `membership_ids` | `map(string)` | Membership resource names keyed by composite key. |
| `membership_group_keys` | `map(string)` | Parent group key for each membership. |
| `membership_member_emails` | `map(string)` | Member email for each membership. |
| `customer_parent` | `string` | Resolved Cloud Identity parent path (`customers/<id>`). |
| `common_tags` | `map(string)` | Governance metadata generated by this module call. |

---

## Usage Example

```hcl
module "gcp_group" {
  source = "../../modules/security/gcp_group"

  customer_id = "C0xxxxxxx"

  tags = {
    owner       = "platform-team"
    environment = "production"
  }

  groups = [
    # Security group for platform engineers — safe for IAM bindings
    {
      key          = "platform-engineers"
      email        = "platform-engineers@example.com"
      display_name = "Platform Engineers"
      description  = "Platform team members with infrastructure access"
      labels       = { "cloudidentity.googleapis.com/groups.security" = "" }

      members = [
        { key = "alice", member_email = "alice@example.com", roles = ["MEMBER"] },
        { key = "bob",   member_email = "bob@example.com",   roles = ["MEMBER", "MANAGER"] }
      ]
    },
    # Discussion group for data team
    {
      key          = "data-team"
      email        = "data-team@example.com"
      display_name = "Data Team"
      labels       = { "cloudidentity.googleapis.com/groups.discussion_forum" = "" }

      members = [
        { key = "carol", member_email = "carol@example.com", roles = ["OWNER"] },
        { key = "dave",  member_email = "dave@example.com",  roles = ["MEMBER"] }
      ]
    }
  ]
}
```

---

## Using Groups as IAM Principals

Once created, reference groups in IAM bindings using the `group:` principal format:

```hcl
resource "google_project_iam_member" "platform_viewer" {
  project = "my-project"
  role    = "roles/viewer"
  member  = "group:platform-engineers@example.com"
}
```

Or use with the [GCP IAM module](../../security/gcp_iam/README.md):

```hcl
members = [
  {
    key      = "platform-eng-viewer"
    member   = "group:platform-engineers@example.com"
    role     = "roles/viewer"
    scope    = "project"
    resource = "my-project"
  }
]
```

---

## Validation Behavior

- `groups[*].key` values must be unique.
- `groups[*].email` values must be unique.
- `groups[*].labels` must contain at least one entry.
- `initial_group_config` must be `EMPTY`, `WITH_INITIAL_OWNER`, or `INITIAL_GROUP_CONFIG_UNSPECIFIED`.
- `members[*].roles` must be non-empty and contain only `MEMBER`, `MANAGER`, or `OWNER`.

---

## Related Docs

- [Cloud Identity Groups Overview](https://cloud.google.com/identity/docs/groups)
- [Cloud Identity Groups API](https://cloud.google.com/identity/docs/reference/rest/v1/groups)
- [Using Groups in IAM Policies](https://cloud.google.com/iam/docs/groups-in-cloud-console)
- [Cloud Identity Groups Service Explainer](./gcp-group.md)
- [Cloud Identity Groups Deployment Plan](../../../tf-plans/gcp_group/README.md)
- [GCP IAM Module](../../security/gcp_iam/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
