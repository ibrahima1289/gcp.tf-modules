project_id = "main-project-456789"
region     = "us-central1"

tags = {
  owner       = "data-platform"
  environment = "production"
  team        = "platform"
}

clusters = [

  # ── Primary cluster — HA production, REGIONAL primary + read pool ───────────
  # REGIONAL availability_type provides automatic zone-level HA failover.
  # The network must have Private Service Access (PSA) pre-configured.
  {
    key    = "app-alloydb"
    name   = "my-app-alloydb-prod"
    region = "us-central1"
    create = true

    # PSA-peered VPC — AlloyDB is private-IP only
    network      = "projects/main-project-456789/global/networks/my-vpc"
    cluster_type = "PRIMARY"

    # Automated daily backups retained for 14 days (count-based)
    automated_backup_enabled         = true
    automated_backup_start_time      = "03:00"
    automated_backup_days_of_week    = ["MONDAY", "WEDNESDAY", "FRIDAY"]
    automated_backup_retention_count = 14
    automated_backup_retention_days  = 0 # 0 = use count-based retention
    automated_backup_location        = "us"

    # Continuous backup (PITR) — recover to any second within 14 days
    continuous_backup_enabled         = true
    continuous_backup_recovery_window = 14

    # Admin user — in production, source the password from Secret Manager
    initial_user     = "alloydbadmin"
    initial_password = "changeme-use-secret-manager"

    # Maintenance: major upgrades during low-traffic window (Sunday 02:00 UTC)
    maintenance_window_day  = "SUNDAY"
    maintenance_window_hour = 2

    # CMEK: leave empty for Google-managed key, or supply a KMS key resource name
    kms_key_name = ""

    deletion_protection = true

    labels = { app = "my-app" }

    # Primary read/write instance — 8 vCPUs, REGIONAL HA, columnar engine on
    primary = {
      instance_id       = "primary"
      cpu_count         = 8
      availability_type = "REGIONAL"
      database_flags = {
        "max_connections"             = "500"
        "log_min_duration_statement"  = "1000"
        "alloydb_enable_auto_explain" = "off"
      }
      require_connectors             = false # set true to force AlloyDB Auth Proxy
      ssl_mode                       = "ENCRYPTED_ONLY"
      enable_public_ip               = false
      columnar_engine_enabled        = true
      columnar_engine_memory_size_gb = 0 # 0 = auto-sized by AlloyDB
    }

    # Read pool — 4 vCPUs × 2 nodes for horizontal read scaling
    read_pools = [
      {
        instance_id        = "read-pool-1"
        cpu_count          = 4
        node_count         = 2
        database_flags     = {}
        require_connectors = false
        ssl_mode           = "ENCRYPTED_ONLY"
        enable_public_ip   = false
        create             = true
      }
    ]
  },

  # ── Dev cluster — ZONAL, smaller footprint, no read pool ────────────────────
  # ZONAL availability_type reduces cost for non-critical environments.
  # deletion_protection = false allows easy teardown during development.
  {
    key    = "dev-alloydb"
    name   = "my-app-alloydb-dev"
    region = "us-central1"
    create = true

    network      = "projects/main-project-456789/global/networks/my-vpc"
    cluster_type = "PRIMARY"

    automated_backup_enabled         = true
    automated_backup_start_time      = "04:00"
    automated_backup_days_of_week    = ["MONDAY"]
    automated_backup_retention_count = 7
    automated_backup_retention_days  = 0

    continuous_backup_enabled         = true
    continuous_backup_recovery_window = 7

    initial_user     = "alloydbadmin"
    initial_password = "changeme-dev"

    maintenance_window_day  = "SATURDAY"
    maintenance_window_hour = 3

    kms_key_name        = ""
    deletion_protection = false

    labels = { app = "my-app", env = "dev" }

    primary = {
      instance_id                    = "primary"
      cpu_count                      = 2 # smallest vCPU size for dev
      availability_type              = "ZONAL"
      database_flags                 = {}
      require_connectors             = false
      ssl_mode                       = "ENCRYPTED_ONLY"
      enable_public_ip               = false
      columnar_engine_enabled        = false
      columnar_engine_memory_size_gb = 0
    }

    read_pools = [] # no read pool for dev
  },

  # ── Disabled entry — toggle create = false to skip without removing config ──
  {
    key    = "staging-alloydb"
    name   = "my-app-alloydb-staging"
    create = false # disabled; set true to provision

    network = "projects/main-project-456789/global/networks/my-vpc"

    initial_password = "changeme-staging"

    primary = {
      cpu_count = 4
    }

    read_pools = []
  }
]
