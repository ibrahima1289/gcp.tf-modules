# ---------------------------------------------------------------------------
# Step 1: call the reusable GCP Folder module.
# ---------------------------------------------------------------------------
module "folder" {
  source = "../../modules/hierarchy/folder"

  # -------------------------------------------------------------------------
  # Step 2: provider region.
  # -------------------------------------------------------------------------
  region = var.region

  # -------------------------------------------------------------------------
  # Step 3: default fallback parent for folders.
  # -------------------------------------------------------------------------
  default_parent = var.default_parent

  # -------------------------------------------------------------------------
  # Step 4: common labels/tags merged with created_date metadata.
  # -------------------------------------------------------------------------
  labels = merge(var.labels, {
    created_date = local.created_date
    managed_by   = "terraform"
  })

  # -------------------------------------------------------------------------
  # Step 5: create multiple folders and optional nesting.
  # -------------------------------------------------------------------------
  folders = var.folders

  # -------------------------------------------------------------------------
  # Step 6: optional folder-level IAM, policies, sinks, and contacts.
  # -------------------------------------------------------------------------
  folder_iam_members        = var.folder_iam_members
  folder_policies           = var.folder_policies
  folder_log_sinks          = var.folder_log_sinks
  folder_essential_contacts = var.folder_essential_contacts
}
