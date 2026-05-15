# ---------------------------------------------------------------------------
# Default project for all VM resources.
# ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID where all VM instances are created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 chars, start with a lowercase letter, and contain only lowercase letters, digits, or hyphens."
  }
}

# ---------------------------------------------------------------------------
# Default region — used when vm.zone is not explicitly set.
# ---------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region. Used as a fallback when zone is derived from region."
  type        = string
  default     = "us-central1"
}

# ---------------------------------------------------------------------------
# Common governance labels applied to all VM instances.
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Common governance labels merged with managed_by and created_date."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# VM instance definitions.
# Each entry creates one google_compute_instance resource.
# All optional fields have safe defaults so you only need to specify what
# differs from the standard configuration.
# ---------------------------------------------------------------------------
variable "vms" {
  description = "List of VM instance definitions. Each entry creates one google_compute_instance."
  type = list(object({
    # Unique stable key used as the Terraform for_each map key.
    key = string
    # Set false to skip creation while keeping the entry in tfvars for reference.
    create = optional(bool, true)
    # GCE instance resource name.
    name = string
    # Zone where the instance is created.
    zone = string
    # GCE machine type (e.g. e2-medium, n2-standard-4, c2-standard-8).
    machine_type = optional(string, "e2-medium")

    # ---------------------------------------------------------------------------
    # Boot disk
    # ---------------------------------------------------------------------------
    # Source image for the boot disk (family or self-link).
    image = optional(string, "debian-cloud/debian-12")
    # Boot disk size in GB.
    disk_size_gb = optional(number, 20)
    # Boot disk type: pd-standard, pd-balanced, pd-ssd, or hyperdisk-balanced.
    disk_type = optional(string, "pd-balanced")
    # Set true to keep the boot disk after the instance is destroyed.
    keep_disk = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Additional data disks attached to the instance.
    # ---------------------------------------------------------------------------
    data_disks = optional(list(object({
      # Disk resource name.
      name = string
      # Size in GB.
      size_gb = optional(number, 50)
      # Disk type: pd-standard, pd-balanced, pd-ssd, or hyperdisk-balanced.
      type = optional(string, "pd-balanced")
      # Device name exposed inside the OS.
      device_name = optional(string, "")
      # Set true to delete the disk when the instance is destroyed.
      auto_delete = optional(bool, true)
    })), [])

    # ---------------------------------------------------------------------------
    # Networking
    # ---------------------------------------------------------------------------
    # VPC network name or self-link.
    network = optional(string, "default")
    # Subnetwork name or self-link. Leave empty to use the default subnetwork.
    subnetwork = optional(string, "")
    # Set false to create an internal-only instance with no external IP.
    external_ip = optional(bool, true)
    # Static external IP self-link. Leave empty to use an ephemeral IP.
    static_ip = optional(string, "")
    # Network tags used for firewall rule targeting.
    network_tags = optional(list(string), [])

    # ---------------------------------------------------------------------------
    # Identity & access
    # ---------------------------------------------------------------------------
    # Service account email. Defaults to the Compute Engine default SA.
    service_account_email = optional(string, "")
    # OAuth scopes granted to the service account.
    service_account_scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])

    # ---------------------------------------------------------------------------
    # Scheduling & availability
    # ---------------------------------------------------------------------------
    # Set true to use Spot VMs (preemptible with automatic restart disabled).
    spot = optional(bool, false)
    # Allow Terraform to stop a running VM to apply changes (e.g. machine type resize).
    allow_stopping_for_update = optional(bool, true)
    # Set false to disable automatic restart on infrastructure maintenance events.
    automatic_restart = optional(bool, true)
    # Maintenance behavior: MIGRATE (live migrate) or TERMINATE (stop during maintenance).
    on_host_maintenance = optional(string, "MIGRATE")

    # ---------------------------------------------------------------------------
    # Startup & metadata
    # ---------------------------------------------------------------------------
    # Shell script executed at first boot.
    startup_script = optional(string, "")
    # Arbitrary key/value metadata attached to the instance.
    metadata = optional(map(string), {})

    # ---------------------------------------------------------------------------
    # Shielded VM
    # ---------------------------------------------------------------------------
    # Enable Shielded VM features (Secure Boot, vTPM, Integrity Monitoring).
    enable_shielded_vm   = optional(bool, false)
    enable_secure_boot   = optional(bool, false)
    enable_vtpm          = optional(bool, true)
    enable_integrity_mon = optional(bool, true)

    # ---------------------------------------------------------------------------
    # Deletion protection
    # ---------------------------------------------------------------------------
    # Set true to prevent accidental instance deletion in production.
    deletion_protection = optional(bool, false)

    # ---------------------------------------------------------------------------
    # Instance-level labels merged with common labels.
    # ---------------------------------------------------------------------------
    labels = optional(map(string), {})
  }))

  default = []

  validation {
    condition     = length(distinct([for vm in var.vms : vm.key])) == length(var.vms)
    error_message = "vms[*].key values must be unique."
  }
}
