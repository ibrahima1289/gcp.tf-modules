# GCP AlloyDB Deployment Plan

Wrapper configuration for the [GCP AlloyDB module](../../modules/database/gcp_alloyDB/README.md). Deploys one or many [AlloyDB for PostgreSQL](https://cloud.google.com/alloydb/docs) clusters with primary instances, read pool instances, automated and continuous backups, CMEK, and maintenance window controls.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_alloydb/
├── providers.tf       → GCS backend (optional) + google provider
├── variables.tf       → project_id, region, tags, clusters[]
├── locals.tf          → created_date
├── main.tf            → module "gcp_alloydb" call
├── outputs.tf         → pass-through outputs from module
├── terraform.tfvars   → example values for all configurations
└── README.md          → this file
        ↓
modules/database/gcp_alloyDB/
├── google_alloydb_cluster          (one per clusters[] entry)
├── google_alloydb_instance PRIMARY (one per active cluster)
└── google_alloydb_instance READ_POOL (one per read_pools[] entry)
```

Resource relationships:

```text
VPC Network (pre-existing, PSA configured)
        │
        ▼
google_alloydb_cluster
        │
        ├── google_alloydb_instance  [PRIMARY]  ← read/write endpoint
        │        └── machine_config (cpu_count)
        │        └── ssl_config + query_insights_config
        │
        └── google_alloydb_instance  [READ_POOL] ← load-balanced reads
                 └── read_pool_config (node_count)
                 └── machine_config (cpu_count per node)
```

---

## Prerequisites

- GCP project with [AlloyDB API](https://cloud.google.com/alloydb/docs/project-enable-access) enabled (`alloydb.googleapis.com`)
- VPC network with [Private Service Access](https://cloud.google.com/alloydb/docs/configure-connectivity) (PSA) pre-configured
- IAM role: [`roles/alloydb.admin`](https://cloud.google.com/alloydb/docs/auth-and-access/overview) on the project
- For CMEK: KMS key with `roles/cloudkms.cryptoKeyEncrypterDecrypter` granted to AlloyDB service account
- Terraform `>= 1.5` and Google provider `>= 6.0`

---

## Apply Workflow

```bash
# 1. Authenticate
gcloud auth application-default login --no-launch-browser

# 2. Set project
gcloud config set project my-project-id

# 3. Enable required APIs
gcloud services enable alloydb.googleapis.com servicenetworking.googleapis.com \
  --project=my-project-id

# 4. Configure PSA on your VPC (one-time setup per network)
gcloud compute addresses create google-managed-services-my-vpc \
  --global --purpose=VPC_PEERING --prefix-length=16 \
  --network=my-vpc --project=my-project-id

gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services-my-vpc \
  --network=my-vpc --project=my-project-id

# 5. Update terraform.tfvars with your project_id, network, and cluster definitions

# 6. Initialize
terraform init

# 7. Review
terraform plan -out=tfplan

# 8. Apply
terraform apply tfplan

# 9. Inspect outputs
terraform output primary_ip_addresses
terraform output read_pool_ip_addresses
```

> **Destroy note**: Set `deletion_protection = false` on clusters before running `terraform destroy`.

---

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|:--------:|---------|-------------|
| `project_id` | `string` | ✅ | — | GCP project ID |
| `region` | `string` | ➖ | `us-central1` | Default region for all clusters |
| `tags` | `map(string)` | ➖ | `{}` | Governance labels for all cluster label maps |
| `clusters` | `list(object)` | ✅ | — | One or many AlloyDB cluster configurations |

See [module variables](../../modules/database/gcp_alloyDB/README.md#variables) for the full `clusters[]` field reference.

---

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_ids` | Cluster resource IDs keyed by cluster key |
| `cluster_names` | Cluster IDs (name field) keyed by cluster key |
| `primary_instance_ids` | Primary instance resource IDs keyed by cluster key |
| `primary_instance_names` | Primary instance names keyed by cluster key |
| `primary_ip_addresses` | Private IPs of primary instances — use as connection endpoint |
| `read_pool_ids` | Read pool resource IDs keyed by `<cluster_key>--<instance_id>` |
| `read_pool_ip_addresses` | Private IPs of read pool instances — use for read-only connections |
| `cluster_regions` | Resolved regions keyed by cluster key |
| `common_tags` | Governance labels applied by this run |

---

## Example Configurations

### Minimal single-cluster

```hcl
clusters = [
  {
    key              = "app-db"
    name             = "my-app-alloydb-prod"
    network          = "projects/my-project-id/global/networks/my-vpc"
    initial_password = "changeme"

    primary = {
      cpu_count         = 4
      availability_type = "REGIONAL"
    }

    read_pools = []
  }
]
```

### Production HA cluster with read pool

```hcl
clusters = [
  {
    key    = "app-db"
    name   = "my-app-alloydb-prod"
    region = "us-central1"
    network = "projects/my-project-id/global/networks/my-vpc"

    automated_backup_enabled         = true
    automated_backup_retention_count = 14
    continuous_backup_recovery_window = 14
    initial_password                 = "changeme"
    deletion_protection              = true

    primary = {
      cpu_count         = 8
      availability_type = "REGIONAL"
      database_flags    = { "max_connections" = "500" }
      columnar_engine_enabled = true
    }

    read_pools = [
      {
        instance_id = "read-pool-1"
        cpu_count   = 4
        node_count  = 2
      }
    ]
  }
]
```

### Disable a cluster without removing config

```hcl
{
  key    = "old-cluster"
  name   = "my-app-alloydb-old"
  create = false  # set true to re-enable
  network = "projects/my-project-id/global/networks/my-vpc"
  initial_password = ""
  primary  = {}
  read_pools = []
}
```

---

## Connecting to AlloyDB

AlloyDB instances are **private IP only** — direct TCP is available only from resources on the peered VPC.

```bash
# Option 1: AlloyDB Auth Proxy (recommended; provides IAM auth + TLS)
./alloydb-auth-proxy \
  --address 127.0.0.1 --port 5432 \
  projects/my-project-id/locations/us-central1/clusters/my-app-alloydb-prod/instances/my-app-alloydb-prod-primary

psql -h 127.0.0.1 -U alloydbadmin -d postgres

# Option 2: Direct private IP from a VM in the same VPC
psql -h <primary_ip> -U alloydbadmin -d postgres
```

---

## See Also

- [Module documentation](../../modules/database/gcp_alloyDB/README.md)
- [Service explainer](../../modules/database/gcp_alloyDB/gcp-alloydb.md) — AlloyDB concepts and architecture
- [AlloyDB product documentation](https://cloud.google.com/alloydb/docs)
- [AlloyDB Auth Proxy](https://cloud.google.com/alloydb/docs/auth-proxy/overview)
- [Private Service Access setup](https://cloud.google.com/alloydb/docs/configure-connectivity)
