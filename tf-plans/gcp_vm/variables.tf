variable "project_id" {
  description = "GCP project ID where all VM instances are created."
  type        = string
}

variable "region" {
  description = "Default GCP region for VM resources."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels applied to all instances."
  type        = map(string)
  default     = {}
}

variable "vms" {
  description = "List of VM instance definitions passed directly to the gcp_vm module."
  type = list(object({
    key          = string
    create       = optional(bool, true)
    name         = string
    zone         = string
    machine_type = optional(string, "e2-medium")
    image        = optional(string, "debian-cloud/debian-12")
    disk_size_gb = optional(number, 20)
    disk_type    = optional(string, "pd-balanced")
    keep_disk    = optional(bool, false)
    data_disks = optional(list(object({
      name        = string
      size_gb     = optional(number, 50)
      type        = optional(string, "pd-balanced")
      device_name = optional(string, "")
      auto_delete = optional(bool, true)
    })), [])
    network                   = optional(string, "default")
    subnetwork                = optional(string, "")
    external_ip               = optional(bool, true)
    static_ip                 = optional(string, "")
    network_tags              = optional(list(string), [])
    service_account_email     = optional(string, "")
    service_account_scopes    = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    spot                      = optional(bool, false)
    allow_stopping_for_update = optional(bool, true)
    automatic_restart         = optional(bool, true)
    on_host_maintenance       = optional(string, "MIGRATE")
    startup_script            = optional(string, "")
    metadata                  = optional(map(string), {})
    enable_shielded_vm        = optional(bool, false)
    enable_secure_boot        = optional(bool, false)
    enable_vtpm               = optional(bool, true)
    enable_integrity_mon      = optional(bool, true)
    deletion_protection       = optional(bool, false)
    labels                    = optional(map(string), {})
  }))
  default = []
}
