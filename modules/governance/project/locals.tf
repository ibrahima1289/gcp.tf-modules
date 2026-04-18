# locals.tf

locals {
  default_labels = {
    managed_by = "terraform"
  }

  base_project = {
    project_id      = var.project_id
    name            = var.name
    billing_account = var.billing_account
    org_id          = var.org_id
    folder_id       = var.folder_id
    enable_services = var.enable_services
    labels          = var.labels
    prevent_destroy = var.prevent_destroy
  }

  all_projects = concat([local.base_project], [
    for p in var.additional_projects : {
      project_id      = p.project_id
      name            = p.name
      billing_account = try(p.billing_account, "")
      org_id          = try(p.org_id, "")
      folder_id       = try(p.folder_id, "")
      enable_services = try(p.enable_services, [])
      labels          = try(p.labels, {})
      prevent_destroy = try(p.prevent_destroy, var.prevent_destroy)
    }
  ])

  projects_map = {
    for p in local.all_projects : p.project_id => p
  }

  protected_projects_map = {
    for project_id, project in local.projects_map : project_id => project
    if project.prevent_destroy
  }

  unprotected_projects_map = {
    for project_id, project in local.projects_map : project_id => project
    if !project.prevent_destroy
  }

  project_services = flatten([
    for p in local.all_projects : [
      for s in p.enable_services : {
        key        = "${p.project_id}/${s}"
        project_id = p.project_id
        service    = s
      }
    ]
  ])

  project_services_map = {
    for ps in local.project_services : ps.key => ps
  }

  created_project_ids = merge(
    { for k, p in google_project.protected : k => p.project_id },
    { for k, p in google_project.standard : k => p.project_id }
  )

  created_project_numbers = merge(
    { for k, p in google_project.protected : k => p.number },
    { for k, p in google_project.standard : k => p.number }
  )
}
