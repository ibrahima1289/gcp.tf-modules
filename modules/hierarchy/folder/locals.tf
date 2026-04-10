locals {
  # ---------------------------------------------------------------------------
  # Created date stamp for module metadata.
  # ---------------------------------------------------------------------------
  created_date = formatdate("YYYY-MM-DD", timestamp())

  # ---------------------------------------------------------------------------
  # Common labels/tags used for documentation and metadata.
  # ---------------------------------------------------------------------------
  common_labels = merge(var.labels, {
    created_date = local.created_date
    managed_by   = "terraform"
  })

  # ---------------------------------------------------------------------------
  # Convert input lists to maps for stable for_each identity.
  # ---------------------------------------------------------------------------
  folders_map = {
    for f in var.folders : f.key => f
  }

  # Top-level folders are attached directly to an explicit/default parent.
  top_level_folders_map = {
    for key, folder in local.folders_map : key => folder
    if trimspace(folder.parent_folder_key) == ""
  }

  # Nested folders are attached to a top-level folder created in this module.
  nested_folders_map = {
    for key, folder in local.folders_map : key => folder
    if trimspace(folder.parent_folder_key) != ""
  }

  folder_iam_members_map = {
    for m in var.folder_iam_members : m.key => m
  }

  folder_policies_map = {
    for p in var.folder_policies : p.key => p
  }

  folder_log_sinks_map = {
    for s in var.folder_log_sinks : s.key => s
  }

  folder_essential_contacts_map = {
    for c in var.folder_essential_contacts : c.key => c
  }

  # Unified map for all created folder resource names.
  folder_resource_names = merge(
    { for k, v in google_folder.top_level : k => v.name },
    { for k, v in google_folder.nested : k => v.name }
  )

  # Unified map for all created folder display names.
  folder_display_names = merge(
    { for k, v in google_folder.top_level : k => v.display_name },
    { for k, v in google_folder.nested : k => v.display_name }
  )
}
