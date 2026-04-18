# GCP Cloud SQL Deployment Plan

Wrapper configuration for the [GCP Cloud SQL module](../../modules/database/gcp_cloud_sql/README.md). Deploys one or many Cloud SQL instances (MySQL, PostgreSQL, SQL Server) with databases, users, backups, private IP, and Query Insights.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_cloud_sql/
├── providers.tf       → GCS backend (optional) + google provider
├── variables.tf       → project_id, region, tags, instances[]
├── locals.tf          → created_date
├── main.tf            → module "gcp_cloud_sql" call
├── outputs.tf         → pass-through outputs from module
├── terraform.tfvars   → example values for all configurations
└── README.md          → this file
        ↓
modules/database/gcp_cloud_sql/
├── google_sql_database_instance
├── google_sql_database
└── google_sql_user
```

---

## Prerequisites

- GCP project with Cloud SQL Admin API enabled (`sqladmin.googleapis.com`)
- Terraform `>= 1.5` and Google provider `>= 6.0`
- For **private IP**: VPC network with [Private Service Access](https://cloud.google.com/sql/docs/postgres/configure-private-services-access) configured
- IAM role: `roles/cloudsql.admin` on the project

---

## Apply Workflow

```bash
# 1. Authenticate
gcloud auth application-default login --no-launch-browser

# 2. Set project
gcloud config set project my-project-id

# 3. Enable required API
gcloud services enable sqladmin.googleapis.com --project=my-project-id

# 4. Configure terraform.tfvars with your project_id and instance definitions

# 5. Initialize
terraform init

# 6. Review
terraform plan -out=tfplan

# 7. Apply
terraform apply tfplan

# 8. Inspect outputs
terraform output instance_connection_names
terraform output public_ip_addresses
terraform output private_ip_addresses
```

> **Destroy note**: Set `deletion_protection = false` on instances before running `terraform destroy`.

---

## Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `project_id` | `string` | ✅ | GCP project ID |
| `region` | `string` | ➖ | Default region (`us-central1`) |
| `tags` | `map(string)` | ➖ | Governance tags for user_labels |
| `instances` | `list(object)` | ✅ | One or many Cloud SQL instance configs |

See [module variables](../../modules/database/gcp_cloud_sql/README.md#variables) for the full `instances[]` field reference.

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_connection_names` | `project:region:instance` — use with Cloud SQL Auth Proxy |
| `public_ip_addresses` | Public IPs for instances with `ipv4_enabled = true` |
| `private_ip_addresses` | Private IPs for instances on a VPC |
| `instance_ids` | Resource IDs keyed by instance key |
| `database_ids` | Database resource IDs |
| `user_ids` | User resource IDs |
| `common_tags` | Governance tags applied by this run |

---

## Example Configurations

### Minimal PostgreSQL instance

```hcl
instances = [
  {
    key              = "mydb"
    name             = "my-postgres-dev"
    database_version = "POSTGRES_15"
    tier             = "db-f1-micro"
    databases        = [{ name = "myapp" }]
    users            = [{ name = "myuser", password = "changeme" }]
  }
]
```

### High-availability PostgreSQL with private IP

```hcl
instances = [
  {
    key               = "prod-db"
    name              = "my-postgres-prod"
    database_version  = "POSTGRES_15"
    availability_type = "REGIONAL"
    tier              = "db-n1-standard-4"
    disk_size         = 100

    point_in_time_recovery_enabled = true
    ipv4_enabled    = false
    private_network = "projects/my-project/global/networks/my-vpc"
  }
]
```

### MySQL with public IP and CIDR allowlist

```hcl
instances = [
  {
    key              = "analytics"
    name             = "my-mysql-dev"
    database_version = "MYSQL_8_0"
    binary_log_enabled = true

    authorized_networks = [
      { name = "office", value = "203.0.113.0/24" }
    ]
  }
]
```

### Skipping an instance without removing it

```hcl
instances = [
  { key = "old-db", name = "my-old-db", database_version = "POSTGRES_14", tier = "db-f1-micro", create = false }
]
```

---

## Related Docs

- [GCP Cloud SQL Module](../../modules/database/gcp_cloud_sql/README.md)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy)
- [Private Service Access for Cloud SQL](https://cloud.google.com/sql/docs/postgres/configure-private-services-access)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
