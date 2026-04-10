# ---------------------------------------------------------------------------
# Step 1: call the reusable GCP Project module for one or many projects.
# ---------------------------------------------------------------------------
module "project" {
  for_each = { for p in var.projects : p.project_id => p }

  source = "../../modules/hierarchy/project"

  # -------------------------------------------------------------------------
  # Step 2: provider region.
  # -------------------------------------------------------------------------
  region = var.region

  # -------------------------------------------------------------------------
  # Step 3: required project values.
  # -------------------------------------------------------------------------
  project_id = each.value.project_id
  name       = each.value.name

  # -------------------------------------------------------------------------
  # Step 4: optional parent, billing, services, and labels.
  # -------------------------------------------------------------------------
  billing_account = try(each.value.billing_account, "")
  org_id          = try(each.value.org_id, "")
  folder_id       = try(each.value.folder_id, "")
  enable_services = try(each.value.enable_services, [])
  labels = merge(
    var.labels,
    try(each.value.labels, {}),
    {
      created_date = local.created_date
      managed_by   = "terraform"
    }
  )

  # -------------------------------------------------------------------------
  # Step 5: accidental deletion guard.
  # -------------------------------------------------------------------------
  prevent_destroy = var.prevent_destroy
}
