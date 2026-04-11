# ---------------------------------------------------------------------------
# Fallback parent for folders that do not set parent values.
# Replace with your numeric Organization ID.
# ---------------------------------------------------------------------------
default_parent = "organizations/123456789012"

region = "us-central1"

labels = {
  environment = "platform"
  owner       = "cloud-team"
  repo        = "gcp-tf-modules"
}

# ---------------------------------------------------------------------------
# Create multiple folders, including nested folder example.
# ---------------------------------------------------------------------------
folders = [
  {
    key          = "platform"
    display_name = "platform"
  },
  {
    key               = "security"
    display_name      = "security"
    parent_folder_key = "platform"
  }
]

# ---------------------------------------------------------------------------
# Optional additive IAM at folder scope.
# ---------------------------------------------------------------------------
folder_iam_members = [
  {
    key        = "platform-viewer-group"
    folder_key = "platform"
    role       = "roles/viewer"
    member     = "group:gcp-folder-admins@example.com"
  }
]

# ---------------------------------------------------------------------------
# Optional OrgPolicy v2 constraints at folder scope.
# ---------------------------------------------------------------------------
folder_policies = [
  {
    key        = "security-disable-serial-port"
    folder_key = "security"
    constraint = "compute.disableSerialPortAccess"
    type       = "boolean"
    enforce    = "TRUE"
  }
]

# ---------------------------------------------------------------------------
# Optional folder log sinks.
# Uncomment and set a real destination before apply.
# ---------------------------------------------------------------------------
# folder_log_sinks = [
#   {
#     key              = "platform-audit-sink"
#     folder_key       = "platform"
#     name             = "platform-audit-sink"
#     destination      = "storage.googleapis.com/my-folder-audit-logs"
#     filter           = "logName:\"cloudaudit.googleapis.com\""
#     include_children = true
#   }
# ]
folder_log_sinks = []

# ---------------------------------------------------------------------------
# Optional essential contacts at folder scope.
# ---------------------------------------------------------------------------
# folder_essential_contacts = [
#   {
#     key                     = "security-contact"
#     folder_key              = "security"
#     email                   = "security@example.com"
#     language_tag            = "en"
#     notification_categories = ["SECURITY", "TECHNICAL"]
#   }
# ]
folder_essential_contacts = []
