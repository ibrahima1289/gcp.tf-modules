# ---------------------------------------------------------------------------
# Protected projects: created with prevent_destroy enabled.
# ---------------------------------------------------------------------------
resource "google_project" "protected" {
  for_each = local.protected_projects_map

  project_id      = each.value.project_id
  name            = each.value.name
  billing_account = each.value.billing_account != "" ? each.value.billing_account : null
  org_id          = each.value.org_id != "" ? each.value.org_id : null
  folder_id       = each.value.folder_id != "" ? each.value.folder_id : null
  labels          = merge(local.default_labels, each.value.labels)

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Standard projects: created without prevent_destroy.
# ---------------------------------------------------------------------------
resource "google_project" "standard" {
  for_each = local.unprotected_projects_map

  project_id      = each.value.project_id
  name            = each.value.name
  billing_account = each.value.billing_account != "" ? each.value.billing_account : null
  org_id          = each.value.org_id != "" ? each.value.org_id : null
  folder_id       = each.value.folder_id != "" ? each.value.folder_id : null
  labels          = merge(local.default_labels, each.value.labels)
}

# ---------------------------------------------------------------------------
# Enable APIs/services for created projects.
# ---------------------------------------------------------------------------
resource "google_project_service" "services" {
  for_each = local.project_services_map

  project = local.created_project_ids[each.value.project_id]
  service = each.value.service
}
