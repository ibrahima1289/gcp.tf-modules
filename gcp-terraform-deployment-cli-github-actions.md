# Terraform Deployment Guide for Google Cloud (CLI + GitHub Actions)

Step-by-step guide to deploy Google Cloud resources with Terraform using:
1. Local CLI workflow
2. GitHub Actions CI/CD workflow (recommended with OIDC, no long-lived JSON keys)

---

## Prerequisites

- Google Cloud project with billing enabled
- Terraform `>= 1.5`
- Google Cloud SDK (`gcloud`) installed
- GitHub repository for CI/CD
- IAM permissions to create service accounts, IAM bindings, and (optionally) state bucket

Recommended tools:
- `gcloud`
- `terraform`
- `git`

---

## 1) Install Google Cloud SDK (`gcloud`)

Choose one method based on your OS.

### Windows (PowerShell + winget)

```powershell
winget install --id Google.CloudSDK --accept-source-agreements --accept-package-agreements
```

### macOS (Homebrew)

```bash
brew install --cask google-cloud-sdk
```

### Linux (interactive installer)

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### Verify install and initialize

```bash
gcloud --version
gcloud init
```

---

## 2) Repository Structure (example)

```text
gcp.tf-modules/
├── modules/
├── tf-plans/
│   ├── gcp_organization/
│   ├── gcp_folder/
│   ├── gcp_project/
│   ├── gcp_subnetworks/
│   ├── gcp_cloud_nat/
│   ├── gcp_cloud_router/
│   ├── gcp_networks/
│   ├── gcp_iam/
│   ├── gcp_cloud_storage/
│   └── gcp_group/
└── README.md
```

You can run Terraform from a root stack (e.g., `tf-plans/<stack>` or your own `envs/dev`).

---

## 3) Terraform Provider and Remote State (GCS)

Create/update Terraform config:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "gcp/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}
```

Create the state bucket once (example):

```bash
gcloud storage buckets create gs://my-terraform-state-bucket \
  --project=my-project-id \
  --location=us-central1 \
  --uniform-bucket-level-access
```

Optional hardening:
- Enable object versioning on the state bucket
- Restrict bucket IAM to Terraform deploy identities only

---

## 4) Deploy from CLI

### A. Authenticate

Use Application Default Credentials:

```bash
gcloud auth application-default login --no-launch-browser

or

gcloud auth login --no-launch-browser
```

Set active project:

```bash
gcloud config set project my-project-id
```

### B. Terraform workflow

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan -var="project_id=my-project-id" -var="region=us-central1"
terraform apply tfplan
```

Destroy (if needed):

```bash
terraform destroy -var="project_id=my-project-id" -var="region=us-central1"
```

---

## 5) Deploy with GitHub Actions (OIDC - Recommended)

This avoids storing long-lived GCP keys in GitHub secrets.

## 5.1 Create Workload Identity Federation

Set variables:

```bash
PROJECT_ID="my-project-id"
PROJECT_NUMBER="123456789012"
POOL_ID="github-pool"
PROVIDER_ID="github-provider"
GITHUB_REPO="owner/repo"
SA_NAME="terraform-deployer"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
```

Create service account:

```bash
gcloud iam service-accounts create ${SA_NAME} \
  --project=${PROJECT_ID} \
  --display-name="Terraform Deployer"
```

Create identity pool and provider:

```bash
gcloud iam workload-identity-pools create ${POOL_ID} \
  --project=${PROJECT_ID} \
  --location="global" \
  --display-name="GitHub Pool"

gcloud iam workload-identity-pools providers create-oidc ${PROVIDER_ID} \
  --project=${PROJECT_ID} \
  --location="global" \
  --workload-identity-pool=${POOL_ID} \
  --display-name="GitHub Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref"
```

Allow GitHub repo to impersonate the service account:

```bash
gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} \
  --project=${PROJECT_ID} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_REPO}"
```

Grant deploy roles to service account (minimum required for your resources):

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor"

# Narrow this in production to least privilege roles per service.
```

## 5.2 Add GitHub Repository Variables

Add these repository variables/secrets:

- `GCP_PROJECT_ID` (variable)
- `GCP_PROJECT_NUMBER` (variable)
- `GCP_WIF_POOL_ID` (variable)
- `GCP_WIF_PROVIDER_ID` (variable)
- `GCP_TERRAFORM_SA` (variable; full SA email)

No JSON key secret required for OIDC.

## 5.3 Workflow file

Create [.github/workflows/terraform-gcp.yml](.github/workflows/terraform-gcp.yml):

```yaml
name: Terraform GCP

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

permissions:
  contents: read
  id-token: write

jobs:
  terraform:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: .

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud (OIDC)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/${{ vars.GCP_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/${{ vars.GCP_WIF_POOL_ID }}/providers/${{ vars.GCP_WIF_PROVIDER_ID }}
          service_account: ${{ vars.GCP_TERRAFORM_SA }}

      - name: Setup gcloud
        uses: google-github-actions/setup-gcloud@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -out=tfplan -var="project_id=${{ vars.GCP_PROJECT_ID }}" -var="region=us-central1"

      - name: Terraform Apply (main branch only)
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan
```

---

## 6) Optional: Safer Promotion Pattern

Recommended production workflow:
- PR: `fmt`, `validate`, `plan` only
- Main protected branch: manual approval before apply
- Separate environments (`dev`, `stage`, `prod`) with separate state prefixes and service accounts

---

## 7) Troubleshooting

- **Error: backend bucket not found**
  - Create GCS bucket first and verify bucket name in backend block.
- **Error: permission denied**
  - Confirm service account roles and Workload Identity binding.
- **Error: invalid provider configuration**
  - Ensure `project_id` and `region` variables are set.
- **State lock/contention issues**
  - Avoid parallel applies against the same state prefix.

---

## 8) Security Best Practices

- Prefer OIDC federation over service account JSON keys.
- Use least-privilege IAM roles instead of broad `roles/editor`.
- Keep separate service accounts and state prefixes per environment.
- Enable audit logging and monitor IAM policy changes.
- Restrict who can approve/apply production Terraform.

---

## Related Docs

- [GCP Module & Service Hierarchy](gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](gcp-services-pricing-guide.md)
- [GCP Organization Deployment Plan](tf-plans/gcp_organization/README.md)
- [GCP Folder Deployment Plan](tf-plans/gcp_folder/README.md)
- [GCP Project Deployment Plan](tf-plans/gcp_project/README.md)
- [GCP Subnetworks Deployment Plan](tf-plans/gcp_subnetworks/README.md)
- [GCP Cloud NAT Deployment Plan](tf-plans/gcp_cloud_nat/README.md)
- [GCP Cloud Router Deployment Plan](tf-plans/gcp_cloud_router/README.md)
- [GCP IAM Deployment Plan](tf-plans/gcp_iam/README.md)
- [GCP Cloud Storage Deployment Plan](tf-plans/gcp_cloud_storage/README.md)
- [GCP Cloud Identity Groups Deployment Plan](tf-plans/gcp_group/README.md)
- [GCP Networks (VPC) Deployment Plan](tf-plans/gcp_networks/README.md)
- [Compute Service Explainers](modules/compute/)
- [Storage Service Explainers](modules/storage/)
- [Networking Service Explainers](modules/networking/)
- [Security Service Explainers](modules/security/)
- [Release Notes](RELEASE.md)
