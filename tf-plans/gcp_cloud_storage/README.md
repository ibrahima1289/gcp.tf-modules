# GCP Cloud Storage Deployment Plan

Wrapper configuration for the [GCP Cloud Storage module](../../modules/storage/gcp_cloud_storage/README.md). Deploys one or many Cloud Storage buckets with versioning, lifecycle management, CMEK encryption, website hosting, logging, and autoclass support.

> Part of [gcp.tf-modules](../../README.md) · [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

---

## Architecture

```text
tf-plans/gcp_cloud_storage/
├── providers.tf         → Terraform version constraints, GCS backend (optional), google provider
├── variables.tf         → Input variables mirroring the module interface
├── locals.tf            → created_date timestamp
├── main.tf              → Module call with merged tags
├── outputs.tf           → Pass-through outputs from the module
└── terraform.tfvars     → Example values for two buckets (data lake + backups)

      ↓ calls

modules/storage/gcp_cloud_storage/
├── variables.tf         → Full variable definitions with validations
├── locals.tf            → buckets_map resolution, label merging, derived sub-maps
├── main.tf              → google_storage_bucket (all dynamic blocks)
├── outputs.tf           → All bucket outputs
└── providers.tf         → Version constraints only
```

---

## Requirements

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` |
| [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 6.0` |
| GCP project with billing enabled | — |
| IAM role: [`roles/storage.admin`](https://cloud.google.com/storage/docs/access-control/iam-roles) on the target project | — |

---

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_id` | `string` | Default GCP project ID for buckets that do not override `project_id`. |

---

## Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | `string` | `"us-central1"` | Default bucket location for items that do not set `location`. |
| `tags` | `map(string)` | `{}` | Governance labels merged into every bucket. |
| `buckets` | `list(object)` | `[]` | One or many bucket definitions. See [module README](../../modules/storage/gcp_cloud_storage/README.md#buckets-object-fields) for full field reference. |

---

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_ids` | Bucket resource IDs keyed by bucket key. |
| `bucket_names` | Bucket names keyed by bucket key. |
| `bucket_urls` | `gs://` URLs keyed by bucket key. |
| `bucket_self_links` | REST API self-links keyed by bucket key. |
| `bucket_locations` | Resolved locations keyed by bucket key. |
| `bucket_projects` | Resolved project IDs keyed by bucket key. |
| `bucket_storage_classes` | Storage class per bucket, keyed by bucket key. |
| `versioning_enabled` | Versioning state per bucket, keyed by bucket key. |
| `common_tags` | Governance tags applied to all buckets. |

---

## Apply Workflow

### 1. Authenticate

```bash
# Application Default Credentials (recommended for local dev)
gcloud auth application-default login

# Or set a service account key (not recommended for production)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa-key.json"
```

### 2. Configure variables

Edit `terraform.tfvars` with your project ID and bucket definitions:

```hcl
project_id = "my-data-project"
region     = "us-central1"

tags = {
  owner       = "data-platform"
  environment = "production"
}

buckets = [
  {
    key                         = "data-lake"
    name                        = "my-company-data-lake-prod"
    location                    = "US"
    storage_class               = "STANDARD"
    versioning_enabled          = true
    uniform_bucket_level_access = true
    public_access_prevention    = "enforced"

    lifecycle_rules = [
      {
        action_type          = "SetStorageClass"
        action_storage_class = "NEARLINE"
        condition_age        = 30
      }
    ]
  }
]
```

### 3. (Optional) Enable remote state

Uncomment the GCS backend block in `providers.tf` and set your state bucket:

```hcl
backend "gcs" {
  bucket = "my-terraform-state-bucket"
  prefix = "gcp-cloud-storage"
}
```

### 4. Initialize and plan

```bash
cd tf-plans/gcp_cloud_storage
terraform init
terraform plan -out=tfplan
```

### 5. Apply

```bash
terraform apply tfplan
```

### 6. Inspect outputs

```bash
terraform output bucket_urls
terraform output bucket_ids
```

---

## Example Configurations

### Data lake with lifecycle management

```hcl
{
  key           = "data-lake"
  name          = "my-company-data-lake-prod"
  location      = "US"
  storage_class = "STANDARD"

  versioning_enabled          = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rules = [
    {
      action_type          = "SetStorageClass"
      action_storage_class = "NEARLINE"
      condition_age        = 30
    },
    {
      action_type                  = "Delete"
      condition_age                = 365
      condition_with_state         = "ARCHIVED"
      condition_num_newer_versions = 3
    }
  ]
}
```

### CMEK-encrypted bucket

```hcl
{
  key                  = "sensitive"
  name                 = "my-company-sensitive-data"
  location             = "us-central1"
  default_kms_key_name = "projects/my-project/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  log_bucket        = "my-company-access-logs"
  log_object_prefix = "sensitive-bucket/"
}
```

### Static website bucket

```hcl
{
  key                      = "website"
  name                     = "my-company-website"
  location                 = "us-central1"
  public_access_prevention = "inherited"

  website_main_page_suffix = "index.html"
  website_not_found_page   = "404.html"

  cors = [
    {
      origin  = ["https://example.com"]
      method  = ["GET", "HEAD"]
      response_header = ["Content-Type"]
    }
  ]
}
```

---

## Related Docs

- [Cloud Storage Module](../../modules/storage/gcp_cloud_storage/README.md)
- [Cloud Storage Service Explainer](../../modules/storage/gcp_cloud_storage/gcp-cloud-storage.md)
- [Cloud Storage Pricing](https://cloud.google.com/storage/pricing)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [Terraform Deployment Guide](../../gcp-terraform-deployment-cli-github-actions.md)
- [Release Notes](../../RELEASE.md)
