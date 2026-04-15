# Step 1: Create service accounts.
resource "google_service_account" "sa" {
  for_each = local.service_accounts_map

  project      = each.value.project_id
  account_id   = each.value.account_id
  display_name = trimspace(each.value.display_name) != "" ? each.value.display_name : null
  description  = trimspace(each.value.description) != "" ? each.value.description : null
  disabled     = each.value.disabled
}

# Step 2: Create project-scoped custom IAM roles.
resource "google_project_iam_custom_role" "role" {
  for_each = local.project_custom_roles_map

  project     = each.value.resource
  role_id     = each.value.role_id
  title       = each.value.title
  description = trimspace(each.value.description) != "" ? each.value.description : null
  permissions = each.value.permissions
  stage       = each.value.stage
}

# Step 3: Create organization-scoped custom IAM roles.
resource "google_organization_iam_custom_role" "role" {
  for_each = local.org_custom_roles_map

  org_id      = each.value.resource
  role_id     = each.value.role_id
  title       = each.value.title
  description = trimspace(each.value.description) != "" ? each.value.description : null
  permissions = each.value.permissions
  stage       = each.value.stage
}

# Step 4: Create authoritative project IAM bindings.
# WARNING: Authoritative bindings replace ALL existing members for the given role on the target resource.
# Any members not listed here will be removed. Prefer additive members (var.members) for shared roles.
resource "google_project_iam_binding" "binding" {
  for_each = local.project_bindings_map

  project = each.value.resource
  role    = each.value.role
  members = each.value.members
}

# Step 5: Create authoritative folder IAM bindings.
# WARNING: Same authoritative semantics as project bindings above.
resource "google_folder_iam_binding" "binding" {
  for_each = local.folder_bindings_map

  folder  = "folders/${each.value.resource}"
  role    = each.value.role
  members = each.value.members
}

# Step 6: Create authoritative organization IAM bindings.
# WARNING: Same authoritative semantics as project bindings above.
resource "google_organization_iam_binding" "binding" {
  for_each = local.org_bindings_map

  org_id  = each.value.resource
  role    = each.value.role
  members = each.value.members
}

# Step 7: Create additive project IAM member bindings.
# Additive members are safe for shared roles — they add a single member without disturbing others.
resource "google_project_iam_member" "member" {
  for_each = local.project_members_map

  project = each.value.resource
  role    = each.value.role
  member  = each.value.member
}

# Step 8: Create additive folder IAM member bindings.
resource "google_folder_iam_member" "member" {
  for_each = local.folder_members_map

  folder = "folders/${each.value.resource}"
  role   = each.value.role
  member = each.value.member
}

# Step 9: Create additive organization IAM member bindings.
resource "google_organization_iam_member" "member" {
  for_each = local.org_members_map

  org_id = each.value.resource
  role   = each.value.role
  member = each.value.member
}
