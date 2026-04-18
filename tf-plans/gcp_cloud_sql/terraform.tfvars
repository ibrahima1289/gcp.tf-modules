project_id = "my-project-id"
region     = "us-central1"

tags = {
  owner       = "data-platform"
  environment = "production"
  team        = "platform"
}

instances = [

  # ── PostgreSQL 15 — HA production instance with private IP ─────────────────
  # availability_type = "REGIONAL" enables automatic failover to a standby.
  # private_network disables the public IP; use Cloud SQL Auth Proxy to connect.
  {
    key               = "app-postgres"
    name              = "my-app-postgres-prod"
    database_version  = "POSTGRES_15"
    availability_type = "REGIONAL"
    tier              = "db-n1-standard-4"
    disk_size         = 50
    disk_type         = "PD_SSD"

    deletion_protection            = true
    point_in_time_recovery_enabled = true
    backup_enabled                 = true
    retained_backups               = 14
    backup_start_time              = "03:00"

    ipv4_enabled    = false
    ssl_mode        = "ENCRYPTED_ONLY"
    private_network = "projects/my-project-id/global/networks/my-vpc"

    insights_config_enabled = true
    query_string_length     = 2048
    record_application_tags = true
    record_client_address   = true

    database_flags = [
      {
        name  = "max_connections",
        value = "200"
      },
      {
        name  = "log_min_duration_statement",
        value = "500"
      }
    ]

    databases = [
      {
        name      = "appdb",
        charset   = "UTF8",
        collation = "en_US.UTF8"
      },
      {
        name      = "auditdb",
        charset   = "UTF8",
        collation = "en_US.UTF8"
      }
    ]

    users = [
      {
        name     = "appuser",
        password = "changeme-use-secret-manager",
        type     = "BUILT_IN"
      },
      {
        name     = "readonlyuser",
        password = "changeme",
        type     = "BUILT_IN"
      }
    ]

    create = true
  },

  # ── MySQL 8.0 — Zonal dev instance with public IP and CIDR allowlist ───────
  # binary_log_enabled = true is required for MySQL PITR.
  # authorized_networks restricts public IP access to specific CIDRs.
  {
    key               = "analytics-mysql"
    name              = "my-analytics-mysql-dev"
    database_version  = "MYSQL_8_0"
    availability_type = "ZONAL"
    tier              = "db-n1-standard-2"
    disk_size         = 20

    deletion_protection = false
    backup_enabled      = true
    binary_log_enabled  = true # required for MySQL PITR
    retained_backups    = 7

    ipv4_enabled = true
    ssl_mode     = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"

    authorized_networks = [
      { name = "vpn-office", value = "203.0.113.0/24" },
      { name = "ci-runner", value = "198.51.100.10/32" },
    ]

    database_flags = [
      { name = "slow_query_log", value = "on" },
    ]

    databases = [
      { name = "analytics", charset = "utf8mb4", collation = "utf8mb4_unicode_ci" },
    ]

    users = [
      { name = "analytics", password = "changeme", host = "%", type = "BUILT_IN" },
    ]

    create = true
  },

  # ── SQL Server 2022 Standard ────────────────────────────────────────────────
  # ENTERPRISE_PLUS edition is required for SQL Server. Disk > 10 GB required.
  {
    key               = "reporting-sqlserver"
    name              = "my-reporting-sqlserver-prod"
    database_version  = "SQLSERVER_2022_STANDARD"
    edition           = "ENTERPRISE_PLUS"
    availability_type = "ZONAL"
    tier              = "db-custom-4-15360"
    disk_size         = 100

    deletion_protection            = true
    backup_enabled                 = true
    point_in_time_recovery_enabled = true
    retained_backups               = 10

    ipv4_enabled    = false
    ssl_mode        = "ENCRYPTED_ONLY"
    private_network = "projects/my-project-id/global/networks/my-vpc"

    databases = [
      { name = "ReportingDB" },
    ]

    users = [
      { name = "sqladmin", password = "changeme", type = "BUILT_IN" },
    ]

    create = true
  },

  # ── create = false example ──────────────────────────────────────────────────
  # Instance definition retained in config but no resource created.
  {
    key              = "deprecated-db"
    name             = "my-old-db-dev"
    database_version = "POSTGRES_14"
    tier             = "db-f1-micro"
    create           = false # skipped — no resource created
  },

]
