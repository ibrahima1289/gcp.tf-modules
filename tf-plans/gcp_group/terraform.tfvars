# customer_id: Cloud Identity / Workspace directory customer ID.
# Retrieve with: gcloud organizations list  →  directoryCustomerId field.
customer_id = "C0xxxxxxx"

tags = {
  owner       = "platform-team"
  environment = "production"
  team        = "identity"
}

groups = [

  # ── Label: security ────────────────────────────────────────────────────────
  # Use for groups bound to IAM roles. Supported by Google Cloud IAM.
  # initial_group_config = "EMPTY" → group created with no initial members.
  {
    key                  = "platform-engineers"
    email                = "platform-engineers@example.com"
    display_name         = "Platform Engineers"
    description          = "Platform team with infrastructure access"
    labels               = { "cloudidentity.googleapis.com/groups.security" = "" }
    initial_group_config = "EMPTY"
    create               = true

    members = [
      { key = "alice", member_email = "alice@example.com", roles = ["MEMBER"], create = true },
      { key = "bob", member_email = "bob@example.com", roles = ["MEMBER", "MANAGER"], create = true },
      { key = "carol", member_email = "carol@example.com", roles = ["OWNER"], create = true },
    ]
  },

  # ── Label: discussion_forum ────────────────────────────────────────────────
  # General-purpose mailing list / collaboration group.
  # initial_group_config = "WITH_INITIAL_OWNER" → caller added as OWNER on create.
  {
    key                  = "data-team"
    email                = "data-team@example.com"
    display_name         = "Data Team"
    description          = "Data engineering and analytics team"
    labels               = { "cloudidentity.googleapis.com/groups.discussion_forum" = "" }
    initial_group_config = "WITH_INITIAL_OWNER"
    create               = true

    members = [
      { key = "dave", member_email = "dave@example.com", roles = ["MEMBER"], create = true },
      { key = "eve", member_email = "eve@example.com", roles = ["MEMBER"], create = true },
    ]
  },

  # ── Label: dynamic ─────────────────────────────────────────────────────────
  # Membership managed automatically by a CEL query (requires Workspace).
  # initial_group_config = "INITIAL_GROUP_CONFIG_UNSPECIFIED" → API default.
  {
    key                  = "contractors"
    email                = "contractors@example.com"
    display_name         = "Contractors"
    description          = "Dynamic group auto-populated by CEL query"
    labels               = { "cloudidentity.googleapis.com/groups.dynamic" = "" }
    initial_group_config = "INITIAL_GROUP_CONFIG_UNSPECIFIED"
    create               = true

    members = [] # membership managed by dynamic query — no static members
  },

  # ── Label: security + discussion_forum (combined) ──────────────────────────
  # A group can carry multiple labels simultaneously.
  {
    key          = "sre-oncall"
    email        = "sre-oncall@example.com"
    display_name = "SRE On-Call"
    description  = "SRE on-call rotation — IAM-bound and mailing-list enabled"
    labels = {
      "cloudidentity.googleapis.com/groups.security"         = ""
      "cloudidentity.googleapis.com/groups.discussion_forum" = ""
    }
    initial_group_config = "EMPTY"
    create               = true

    members = [
      { key = "frank", member_email = "frank@example.com", roles = ["MEMBER", "MANAGER"], create = true },
    ]
  },

  # ── create = false example ─────────────────────────────────────────────────
  # Keep the definition in config without provisioning the resource.
  {
    key                  = "archived-team"
    email                = "archived-team@example.com"
    display_name         = "Archived Team"
    description          = "Decommissioned group — retained for reference only"
    labels               = { "cloudidentity.googleapis.com/groups.discussion_forum" = "" }
    initial_group_config = "EMPTY"
    create               = false # skipped — no resource created

    members = []
  },

]
