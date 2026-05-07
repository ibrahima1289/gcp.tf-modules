# GCP Pub/Sub — Terraform Deployment Plan

This plan calls the [`gcp_pubsub`](../../modules/app_development/Pub_Sub/README.md) module
and provides `terraform.tfvars` examples for an order-processing pull subscription with
dead-lettering, a push subscription to Cloud Run, a BigQuery IoT ingestion subscription,
and a Cloud Storage archival subscription.

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |
| GCP APIs | `pubsub.googleapis.com` |
| IAM (deployer) | `roles/pubsub.admin` |
| BigQuery subscriptions | Pub/Sub service account needs `roles/bigquery.dataEditor` on the dataset |
| GCS subscriptions | Pub/Sub service account needs `roles/storage.objectCreator` on the bucket |

---

## Quick Start

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Enable required API
gcloud services enable pubsub.googleapis.com --project=my-gcp-project

# 3. Configure variables
cp terraform.tfvars terraform.auto.tfvars
# Edit terraform.auto.tfvars — update project_id and service account emails

# 4. Set create = true for resources you want to deploy

# 5. Initialise and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## File Reference

| File | Purpose |
|------|---------|
| `main.tf` | Module call |
| `variables.tf` | Input variable declarations |
| `locals.tf` | `created_date` helper |
| `outputs.tf` | Pass-through of all module outputs |
| `providers.tf` | Google provider + Terraform version pin |
| `terraform.tfvars` | Examples: pull, push, BigQuery, and GCS subscriptions |

---

## Subscription Type Decision Guide

| Scenario | Subscription Type |
|----------|------------------|
| Worker service polls at its own pace | Pull |
| Cloud Run / Cloud Functions event-driven trigger | Push |
| Real-time data ingestion into BigQuery | BigQuery |
| Archival / audit log to Cloud Storage | Cloud Storage |
| FIFO ordering required | Pull + `enable_message_ordering = true` |
| Exactly-once processing | Pull + `enable_exactly_once_delivery = true` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `schema_ids` | Schema IDs |
| `topic_ids` | Fully-qualified topic IDs |
| `topic_names` | Topic resource names |
| `dead_letter_topic_ids` | Dead-letter topic IDs |
| `subscription_ids` | Fully-qualified subscription IDs |
| `subscription_names` | Subscription resource names |
| `common_labels` | Merged governance labels |

---

## Publish a Test Message

```bash
# Publish a message to a topic
gcloud pubsub topics publish orders \
  --message='{"order_id":"abc123","amount":99.99}' \
  --project=my-gcp-project

# Pull and acknowledge one message (pull subscription)
gcloud pubsub subscriptions pull orders-worker \
  --limit=1 --auto-ack \
  --project=my-gcp-project
```

## Destroy

```bash
terraform destroy
```

> Dead-letter topics are destroyed automatically as they are managed by this module.

---

*Back to [GCP Module Service List](../../gcp-module-service-list.md)*
