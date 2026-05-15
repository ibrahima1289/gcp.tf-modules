project_id = "my-project"
region     = "us-central1"

tags = {
  env     = "dev"
  team    = "platform"
  owner   = "infra-team"
  project = "my-project"
}

# ── VM Instances ──────────────────────────────────────────────────────────────
# Each entry creates one google_compute_instance.
# Set create = false to skip an entry without removing it from tfvars.

vms = [
  # ── Web Server — public-facing with external IP ──────────────────────────
  {
    key            = "web-01"
    create         = true
    name           = "web-server-01"
    zone           = "us-central1-a"
    machine_type   = "e2-medium"
    image          = "debian-cloud/debian-12"
    disk_size_gb   = 20
    disk_type      = "pd-balanced"
    network        = "default"
    external_ip    = true
    network_tags   = ["http-server", "https-server"]
    startup_script = "apt-get update && apt-get install -y nginx && systemctl start nginx"
    labels         = { role = "web" }
  },

  # ── Database Server — internal only with data disk ───────────────────────
  {
    key                 = "db-01"
    create              = false
    name                = "db-server-01"
    zone                = "us-central1-b"
    machine_type        = "n2-standard-4"
    image               = "debian-cloud/debian-12"
    disk_size_gb        = 50
    disk_type           = "pd-ssd"
    network             = "default"
    external_ip         = false
    network_tags        = ["db-server"]
    deletion_protection = true
    data_disks = [
      {
        name    = "db-data-disk"
        size_gb = 500
        type    = "pd-ssd"
      }
    ]
    labels = { role = "database" }
  },

  # ── Spot Batch Worker — preemptible with Shielded VM ─────────────────────
  {
    key                  = "batch-worker-01"
    create               = false
    name                 = "batch-worker-01"
    zone                 = "us-central1-c"
    machine_type         = "e2-standard-8"
    image                = "debian-cloud/debian-12"
    disk_size_gb         = 20
    spot                 = true
    network              = "default"
    external_ip          = false
    enable_shielded_vm   = true
    enable_secure_boot   = true
    enable_vtpm          = true
    enable_integrity_mon = true
    metadata             = { batch-job-id = "job-2026-001" }
    labels               = { role = "batch" }
  }
]
