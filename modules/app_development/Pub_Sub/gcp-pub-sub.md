# Google Cloud Pub/Sub

## Service Overview

[Google Cloud Pub/Sub](https://cloud.google.com/pubsub/docs) is a fully managed, real-time, asynchronous messaging service that decouples message producers (publishers) from message consumers (subscribers). It provides durable, at-least-once message delivery at any scale with sub-second global latency, making it the backbone for event-driven architectures, streaming data pipelines, and service-to-service integration on Google Cloud.

---

## How Pub/Sub Works

```text
Publisher (Cloud Run, Cloud Function, GKE, on-prem app)
        │
        ▼ publish(message)
  ┌─────────────────────────────┐
  │       Pub/Sub Topic         │  ← durable message store
  └─────────────┬───────────────┘
                │  fan-out (multiple subscriptions possible)
    ┌───────────┼────────────────┐
    ▼           ▼                ▼
Subscription A  Subscription B  Subscription C
 (Pull)         (Push → URL)    (BigQuery export)
    │
 Subscriber app polls / receives messages
 → acknowledges each message after processing
```

---

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Topic** | A named channel to which publishers send messages. A topic can have many subscriptions. |
| **Message** | A unit of data (up to 10 MB) sent to a topic. Comprises a base64-encoded body and optional key/value attributes. |
| **Subscription** | A named entity that receives messages from a topic. Each subscription independently tracks message delivery. |
| **Acknowledgement (ack)** | The subscriber signals successful processing. Unacknowledged messages are redelivered. |
| **Ack deadline** | How long Pub/Sub waits for an ack before redelivering (10s–600s, extendable). |
| **Message retention** | How long unacknowledged messages are retained on a subscription (default 7 days, max 31 days). |
| **Ordering key** | When set, messages with the same key are delivered in publish order to a single subscriber. |
| **Dead-letter topic** | A secondary topic where messages are routed after exceeding max delivery attempts. |
| **Snapshot** | A point-in-time bookmark of a subscription's unacknowledged message backlog, usable for replay. |
| **Schema** | Enforces Avro or Protocol Buffer message structure on a topic at publish time. |

---

## Subscription Types

| Type | Description | Best For |
|------|-------------|----------|
| **Pull** | Subscriber calls `pull()` to fetch messages in batches. Full control over consumption rate. | Cloud Run workers, GKE consumers, custom batch processors |
| **Push** | Pub/Sub calls a subscriber's HTTPS endpoint for each message. | Cloud Run services, Cloud Functions, Webhooks |
| **BigQuery** | Pub/Sub writes messages directly into a BigQuery table (no subscriber code). | Real-time analytics ingestion |
| **Cloud Storage** | Pub/Sub writes messages to GCS as files on a configurable schedule. | Archival, batch ingestion |

---

## Message Lifecycle

```text
1. Publisher sends message → topic
2. Pub/Sub stores message durably in regional or global storage
3. Message delivered to each active subscription independently
4. Subscriber receives message:
   - Pull: subscriber calls pull(), processes, calls acknowledge()
   - Push: Pub/Sub HTTP POSTs to endpoint; 2xx response = ack
5. If ack not received within ack deadline → message redelivered
6. After max_delivery_attempts (dead-letter) → forwarded to DLT
7. After message_retention_duration → message permanently deleted
```

---

## Message Ordering

By default, Pub/Sub provides **at-least-once** delivery with **no ordering guarantee**:

- Enable **message ordering** on both the publisher client and the subscription to receive messages with the same `ordering_key` in FIFO order.
- Ordering is per-key and per-region — a single ordering key is always routed to the same partition.
- Enabling ordering slightly reduces throughput; use only when downstream processing requires it.

---

## Fan-Out and Fan-In Patterns

**Fan-out** (one topic → many subscriptions):
```text
Order topic
  ├── Subscription: inventory-service (updates stock)
  ├── Subscription: billing-service   (charges customer)
  └── Subscription: notification-service (sends email)
```
Each service gets an independent copy of every message.

**Fan-in** (many publishers → one topic):
```text
service-A ──┐
service-B ──┼──► events-topic ──► analytics-subscription
service-C ──┘
```
Centralise events from multiple producers into one stream.

---

## Exactly-Once Delivery

Pub/Sub default mode is **at-least-once** (duplicates possible). For **exactly-once** processing:

- Enable `enable_exactly_once_delivery = true` on the subscription.
- Requires subscriber to use the **streaming pull** client library with ack IDs.
- Exactly-once delivery is guaranteed within a single GCP region; cross-region uses at-least-once semantics.

---

## Schemas

Enforce message format at publish time using Avro or Protocol Buffers:

```hcl
resource "google_pubsub_schema" "order_schema" {
  name       = "order-schema"
  type       = "AVRO"
  definition = jsonencode({ ... avro schema ... })
}

resource "google_pubsub_topic" "orders" {
  name = "orders"
  schema_settings {
    schema   = google_pubsub_schema.order_schema.id
    encoding = "JSON"
  }
}
```

---

## Dead-Letter Topics

Route persistently failing messages to a dead-letter topic for inspection and reprocessing:

```hcl
resource "google_pubsub_subscription" "main" {
  name  = "my-subscription"
  topic = google_pubsub_topic.main.name

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }
}
```

---

## Retention and Replay

| Setting | Default | Maximum |
|---------|---------|---------|
| Message retention (topic) | 31 days | 31 days |
| Message retention (subscription) | 7 days | 31 days |
| Ack deadline | 10 seconds | 600 seconds |

Snapshots capture a subscription's backlog at a point in time — replay from a snapshot to reprocess historical messages after a bug fix.

---

## IAM Roles

| Role | Purpose |
|------|---------|
| `roles/pubsub.admin` | Full control of topics and subscriptions |
| `roles/pubsub.editor` | Create and delete topics/subscriptions; publish and subscribe |
| `roles/pubsub.publisher` | Publish messages to topics only |
| `roles/pubsub.subscriber` | Subscribe to and acknowledge messages only |
| `roles/pubsub.viewer` | Read topic/subscription metadata; no message access |

---

## Observability

| Metric | Cloud Monitoring metric |
|--------|------------------------|
| Published message count | `pubsub.googleapis.com/topic/send_message_operation_count` |
| Undelivered message backlog | `pubsub.googleapis.com/subscription/num_undelivered_messages` |
| Oldest unacknowledged message age | `pubsub.googleapis.com/subscription/oldest_unacked_message_age` |
| Pull/Push delivery latency | `pubsub.googleapis.com/subscription/pull_ack_latencies` |
| Dead-letter message count | `pubsub.googleapis.com/subscription/dead_letter_message_count` |

**Alert**: Set an alerting policy on `oldest_unacked_message_age` to detect stuck consumers.

---

## Pricing

| Dimension | Model |
|-----------|-------|
| Data volume | Per TiB of message data published + subscribed |
| Free tier | First 10 GiB per month |
| Message retention | Additional charge for retaining messages beyond 7 days |
| Snapshots | Charged as additional data storage |
| Exactly-once delivery | Additional per-message fee |

> Full pricing: [https://cloud.google.com/pubsub/pricing](https://cloud.google.com/pubsub/pricing)

---

## When to Use Pub/Sub

- **Microservice decoupling**: Services emit events without knowing who consumes them.
- **Event-driven pipelines**: Trigger Cloud Run, Cloud Functions, or Dataflow in response to events.
- **Streaming ingestion**: High-throughput log, metric, or clickstream ingestion into BigQuery or GCS.
- **Notification fan-out**: Broadcast the same event to multiple independent downstream systems.
- **Workflow orchestration**: Coordinate multi-step async workflows (combined with Cloud Tasks or Workflows for ordering).
- **Cross-region replication**: Use Pub/Sub's global replication to bridge regional systems.

---

## Real-World Usage

- **E-commerce order processing**: `order-created` topic fans out to inventory, billing, fulfilment, and email notification services independently.
- **IoT telemetry**: Millions of devices publish sensor readings; Dataflow subscriber aggregates and loads to BigQuery.
- **CI/CD pipeline events**: Cloud Build publishes build status events; Cloud Run subscribers update dashboards and notify Slack.
- **Log aggregation**: Applications publish structured logs to a topic; BigQuery subscription stores all logs in a queryable table.

---

## Security Guidance

- Grant the **minimum required role** — `publisher` for services that only emit events, `subscriber` for consumers.
- Use a **dedicated service account** per topic/subscription consumer rather than sharing credentials.
- Enable **message encryption with CMEK** (Cloud KMS) for topics containing sensitive data.
- Use a **dead-letter topic** to avoid silent message loss on consumer failures.
- Monitor `oldest_unacked_message_age` and alert when it exceeds acceptable thresholds.
- For push subscriptions, validate the `Authorization` header to ensure only Pub/Sub can call your endpoint.

---

## Terraform Resources Commonly Used

| Resource | Purpose |
|----------|---------|
| [`google_pubsub_topic`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | Creates a topic |
| [`google_pubsub_subscription`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | Creates a pull, push, BigQuery, or GCS subscription |
| [`google_pubsub_schema`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_schema) | Defines an Avro or Protobuf schema for a topic |
| [`google_pubsub_topic_iam_member`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam) | Grants IAM roles on a topic |
| [`google_pubsub_subscription_iam_member`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription_iam) | Grants IAM roles on a subscription |
| [`google_project_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | Enables `pubsub.googleapis.com` |

---

## Related Docs

- [Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Pub/Sub Subscription Types](https://cloud.google.com/pubsub/docs/subscriber)
- [Pub/Sub Ordering and Exactly-Once](https://cloud.google.com/pubsub/docs/ordering)
- [Pub/Sub Dead-Letter Topics](https://cloud.google.com/pubsub/docs/dead-letter-topics)
- [API Gateway Explainer](../api_gateway/gcp-api-gateway.md)
- [GCP Service List — Definitions](../../../gcp-service-list-definitions.md)
- [GCP Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
