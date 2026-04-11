# ---------------------------------------------------------------------------
# Replace org_domain or org_id with your real organization values.
# ---------------------------------------------------------------------------

# Look up organization by primary domain.
org_domain = "example.com"

# Alternative: look up by numeric org ID.
# org_id = "123456789012"

region = "us-central1"

labels = {
  environment = "platform"
  owner       = "cloud-team"
  repo        = "gcp-tf-modules"
}

# ---------------------------------------------------------------------------
# IAM members — additive org-level role grants.
# ---------------------------------------------------------------------------
iam_members = [
  {
    key    = "org-viewer-security-group"
    role   = "roles/viewer"
    member = "group:gcp-org-admins@example.com"
  }
]

# ---------------------------------------------------------------------------
# Org policies — OrgPolicy v2 constraints.
# ---------------------------------------------------------------------------
org_policies = [
  {
    key        = "disable-serial-port"
    constraint = "compute.disableSerialPortAccess"
    type       = "boolean"
    enforce    = "TRUE"
  },
  {
    key        = "restrict-vm-external-ip"
    constraint = "compute.vmExternalIpAccess"
    type       = "list"
    deny_all   = true
  }
]

# ---------------------------------------------------------------------------
# Log sinks — organization-wide log export.
# Uncomment and update with a real destination bucket before applying.
# ---------------------------------------------------------------------------
# log_sinks = [
#   {
#     key              = "audit-sink"
#     name             = "org-audit-log-sink"
#     destination      = "storage.googleapis.com/my-org-audit-logs"
#     filter           = "logName:\"cloudaudit.googleapis.com\""
#     include_children = true
#   }
# ]
log_sinks = []

# ---------------------------------------------------------------------------
# Essential contacts — notification recipients for org-level alerts.
# ---------------------------------------------------------------------------
# essential_contacts = [
#   {
#     key                     = "security-team"
#     email                   = "security@example.com"
#     language_tag            = "en"
#     notification_categories = ["SECURITY", "TECHNICAL"]
#   },
#   {
#     key                     = "billing-team"
#     email                   = "billing@example.com"
#     language_tag            = "en"
#     notification_categories = ["BILLING"]
#   }
# ]
essential_contacts = []
