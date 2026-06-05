project_id = "my-project-id"
region     = "us-central1"

tags = {
  owner       = "data-platform"
  environment = "production"
  team        = "platform"
}

instances = [
  # Example 1: Processing-units instance with autoscaling.
  {
    key              = "orders-spanner"
    name             = "orders-spanner-prod"
    display_name     = "Orders Spanner Prod"
    capacity_model   = "PROCESSING_UNITS"
    processing_units = 1000
    instance_edition = "ENTERPRISE"

    autoscaling = {
      enabled                               = true
      min_processing_units                  = 1000
      max_processing_units                  = 3000
      high_priority_cpu_utilization_percent = 65
      storage_utilization_percent           = 75
    }

    databases = [
      {
        key              = "orders-db"
        name             = "orders"
        database_dialect = "GOOGLE_STANDARD_SQL"
        ddl = [
          "CREATE TABLE orders (order_id STRING(36) NOT NULL, amount NUMERIC, created_at TIMESTAMP) PRIMARY KEY (order_id)",
          "CREATE INDEX idx_orders_created_at ON orders(created_at)",
        ]
      }
    ]

    create = true
  },

  # Example 2: Node-based instance with PostgreSQL dialect database.
  {
    key            = "billing-spanner"
    name           = "billing-spanner-prod"
    display_name   = "Billing Spanner Prod"
    capacity_model = "NODES"
    num_nodes      = 1

    databases = [
      {
        key              = "billing-db"
        name             = "billing"
        database_dialect = "POSTGRESQL"
      }
    ]

    create = true
  },

  # Example 3: Disabled entry retained for safe rollout toggles.
  {
    key          = "legacy-spanner"
    name         = "legacy-spanner-dev"
    display_name = "Legacy Spanner Dev"
    create       = false
  }
]
