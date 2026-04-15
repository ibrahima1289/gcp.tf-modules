locals {
  created_date = formatdate("YYYY-MM-DD", timestamp())

  common_tags = merge(
    { managed_by = "terraform", created_date = local.created_date },
    var.tags
  )

  # Resolve project_id for service accounts that do not specify a per-entry project.
  # Entries with create = false are excluded from the map and no resource is created.
  service_accounts_map = {
    for sa in var.service_accounts : sa.key => merge(sa, {
      project_id = trimspace(sa.project_id) != "" ? sa.project_id : var.project_id
    }) if sa.create
  }

  # Separate custom roles by scope and resolve project_id default for project-scoped roles.
  # Entries with create = false are excluded from both maps.
  project_custom_roles_map = {
    for r in var.custom_roles : r.key => merge(r, {
      resource = trimspace(r.resource) != "" ? r.resource : var.project_id
    }) if r.scope == "project" && r.create
  }

  org_custom_roles_map = {
    for r in var.custom_roles : r.key => r if r.scope == "organization" && r.create
  }

  # Separate authoritative IAM bindings by scope.
  # Entries with create = false are excluded and no binding resource is created.
  project_bindings_map = {
    for b in var.bindings : b.key => b if b.scope == "project" && b.create
  }

  folder_bindings_map = {
    for b in var.bindings : b.key => b if b.scope == "folder" && b.create
  }

  org_bindings_map = {
    for b in var.bindings : b.key => b if b.scope == "organization" && b.create
  }

  # Separate additive IAM members by scope.
  # Entries with create = false are excluded and no member resource is created.
  project_members_map = {
    for m in var.members : m.key => m if m.scope == "project" && m.create
  }

  folder_members_map = {
    for m in var.members : m.key => m if m.scope == "folder" && m.create
  }

  org_members_map = {
    for m in var.members : m.key => m if m.scope == "organization" && m.create
  }
}
