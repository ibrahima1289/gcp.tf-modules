# ===========================================================================
# Step 1: VM Instances
# Creates one google_compute_instance per enabled entry in var.vms.
# Uses for_each with a stable key so reordering entries never destroys
# and recreates instances.
# ===========================================================================
resource "google_compute_instance" "vm" {
  for_each = { for vm in var.vms : vm.key => vm if vm.create }

  project      = var.project_id
  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  # Labels: merge common governance labels with instance-level labels.
  labels = merge(local.common_labels, each.value.labels)

  # Network tags enable firewall rules to target this instance.
  tags = each.value.network_tags

  # ---------------------------------------------------------------------------
  # Boot disk — always the first disk; sourced from the specified image.
  # ---------------------------------------------------------------------------
  boot_disk {
    auto_delete = !each.value.keep_disk

    initialize_params {
      image = each.value.image
      size  = each.value.disk_size_gb
      type  = each.value.disk_type
    }
  }

  # ---------------------------------------------------------------------------
  # Additional data disks — iterated over each.value.data_disks.
  # Each disk is created inline with the instance.
  # ---------------------------------------------------------------------------
  dynamic "attached_disk" {
    for_each = each.value.data_disks
    content {
      source      = google_compute_disk.data["${each.key}/${attached_disk.value.name}"].self_link
      device_name = trimspace(attached_disk.value.device_name) != "" ? attached_disk.value.device_name : attached_disk.value.name
    }
  }

  # ---------------------------------------------------------------------------
  # Primary network interface — one NIC per instance.
  # external_ip = false → omit access_config block (no external IP assigned).
  # static_ip   = self-link → use that reserved address as the external IP.
  # ---------------------------------------------------------------------------
  network_interface {
    network    = each.value.network
    subnetwork = trimspace(each.value.subnetwork) != "" ? each.value.subnetwork : null

    dynamic "access_config" {
      for_each = each.value.external_ip ? [1] : []
      content {
        # Empty nat_ip uses an ephemeral IP; populated nat_ip uses a reserved address.
        nat_ip = trimspace(each.value.static_ip) != "" ? each.value.static_ip : null
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Service account — identity used to call Google Cloud APIs from the VM.
  # ---------------------------------------------------------------------------
  dynamic "service_account" {
    for_each = trimspace(each.value.service_account_email) != "" ? [1] : []
    content {
      email  = each.value.service_account_email
      scopes = each.value.service_account_scopes
    }
  }

  # Default service account block when no custom SA is provided.
  dynamic "service_account" {
    for_each = trimspace(each.value.service_account_email) == "" ? [1] : []
    content {
      scopes = each.value.service_account_scopes
    }
  }

  # ---------------------------------------------------------------------------
  # Scheduling — controls Spot VMs, live migration, and restart behaviour.
  # Spot VMs force preemptible = true, automatic_restart = false,
  # and on_host_maintenance = TERMINATE.
  # ---------------------------------------------------------------------------
  scheduling {
    preemptible                 = each.value.spot
    automatic_restart           = each.value.spot ? false : each.value.automatic_restart
    on_host_maintenance         = each.value.spot ? "TERMINATE" : each.value.on_host_maintenance
    provisioning_model          = each.value.spot ? "SPOT" : "STANDARD"
    instance_termination_action = each.value.spot ? "STOP" : null
  }

  # ---------------------------------------------------------------------------
  # Metadata — startup script and arbitrary key/value pairs.
  # ---------------------------------------------------------------------------
  metadata = merge(
    trimspace(each.value.startup_script) != "" ? { startup-script = each.value.startup_script } : {},
    each.value.metadata
  )

  # ---------------------------------------------------------------------------
  # Shielded VM — optional hardware-rooted security features.
  # Only applied when enable_shielded_vm = true.
  # ---------------------------------------------------------------------------
  dynamic "shielded_instance_config" {
    for_each = each.value.enable_shielded_vm ? [1] : []
    content {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_vtpm                 = each.value.enable_vtpm
      enable_integrity_monitoring = each.value.enable_integrity_mon
    }
  }

  # Allow Terraform to stop the VM when applying changes that require a restart
  # (e.g. machine type resize, disk changes).
  allow_stopping_for_update = each.value.allow_stopping_for_update

  # Prevents accidental deletion of running instances in production.
  deletion_protection = each.value.deletion_protection
}

# ===========================================================================
# Step 2: Additional Data Disks
# Created separately so they persist independently of the instance lifecycle.
# Keyed by "<vm_key>/<disk_name>" for stable Terraform state addresses.
# ===========================================================================
resource "google_compute_disk" "data" {
  for_each = {
    for pair in flatten([
      for vm in var.vms : [
        for d in vm.data_disks : {
          key       = "${vm.key}/${d.name}"
          vm_key    = vm.key
          disk      = d
          zone      = vm.zone
          vm_create = vm.create
        }
      ]
    ]) : pair.key => pair if pair.vm_create
  }

  project = var.project_id
  name    = each.value.disk.name
  zone    = each.value.zone
  size    = each.value.disk.size_gb
  type    = each.value.disk.type

  labels = local.common_labels
}
