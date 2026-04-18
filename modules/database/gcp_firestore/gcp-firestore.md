# Google Cloud Firestore

[Cloud Firestore](https://cloud.google.com/firestore/docs) is a serverless, NoSQL document database designed for mobile, web, and server-side application development. It stores data as **documents** organized into **collections**, supports real-time listeners for live data synchronization, and scales automatically with zero infrastructure management. Firestore is the successor to Cloud Datastore and is compatible with the Datastore API in Datastore mode.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Firestore is a multi-region or regional service — data is replicated automatically. There is no instance to provision or VM to maintain. Access is via client SDKs (iOS, Android, Web, Flutter) or the server-side admin SDKs (Node.js, Python, Go, Java, .NET). The REST and gRPC APIs are also available.

| Capability | Description |
|------------|-------------|
| **Serverless** | No infrastructure to manage; pay per read/write/delete operation |
| **Document model** | Hierarchical `collection → document → subcollection` data model |
| **Real-time sync** | onSnapshot listeners push updates to clients within milliseconds |
| **ACID transactions** | Multi-document transactions with optimistic concurrency |
| **Offline support** | Client SDKs cache data locally; sync on reconnect |
| **Automatic scaling** | Scales to millions of concurrent connections without configuration |
| **Composite indexes** | Define compound indexes for complex queries |
| **Security Rules** | Declarative access control evaluated server-side per request |

---

## Core Concepts

### Data Model

```text
Firestore
└── Collection (users)
    └── Document (uid-abc123)
        ├── Field: name = "Alice"
        ├── Field: email = "alice@example.com"
        └── Subcollection (orders)
            └── Document (order-001)
                ├── Field: total = 99.50
                └── Field: status = "shipped"
```

Documents are schema-less — each document in a collection can have different fields.

### Modes

| Mode | Description | Migration |
|------|-------------|-----------|
| **Native mode** | Full Firestore feature set; real-time, offline, mobile SDKs | Default for new projects |
| **Datastore mode** | Backwards-compatible with Cloud Datastore API; no real-time listeners | Migrated Datastore projects |

> You cannot switch between modes after a database is created.

### Indexes

Firestore automatically creates single-field indexes. Composite indexes (multi-field, multi-collection group) must be defined explicitly:

```hcl
resource "google_firestore_index" "orders_by_user_and_date" {
  project    = var.project_id
  collection = "orders"
  fields {
    field_path = "userId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }
}
```

### Security Rules

Firestore Security Rules control access at the document level for client SDK requests:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

Server-side access (admin SDK, Terraform) bypasses Security Rules — use IAM instead.

---

## Queries

Firestore queries are always indexed — a missing index returns an error with a console link to create it.

```javascript
// Simple filter
db.collection("users").where("status", "==", "active").get()

// Compound filter (requires composite index)
db.collection("orders")
  .where("userId", "==", uid)
  .orderBy("createdAt", "desc")
  .limit(10)
  .get()

// Collection group query (across all subcollections named "orders")
db.collectionGroup("orders").where("status", "==", "pending").get()
```

---

## ACID Transactions

Firestore supports multi-document transactions with optimistic locking:

```javascript
await db.runTransaction(async (t) => {
  const doc = await t.get(ref);
  const newBalance = doc.data().balance - amount;
  if (newBalance < 0) throw new Error("Insufficient funds");
  t.update(ref, { balance: newBalance });
});
```

Transactions retry automatically on contention up to 5 times.

---

## Pricing Model

| Operation | Billed per |
|-----------|------------|
| Document reads | Per document |
| Document writes | Per document |
| Document deletes | Per document |
| Storage | Per GiB/month |
| Network egress | Per GiB (outbound to internet) |

> Real-time listeners bill a read per document on initial snapshot and per changed document thereafter. Free tier: 50K reads, 20K writes, 20K deletes per day.

---

## Security Guidance

- Use **Security Rules** for client SDK access and **IAM** (`roles/datastore.user`) for server-side/admin access.
- Avoid wildcard rules (`allow read, write: if true`) — always authenticate and authorize by user identity.
- Use **VPC Service Controls** to restrict Firestore access to trusted service perimeters in regulated environments.
- Enable **Data Access audit logs** for `DATA_READ` and `DATA_WRITE` operations.
- Structure data to minimize document reads — use subcollections and aggregation fields rather than reading entire parent documents for counts.

---

## Related Docs

- [Firestore Documentation](https://cloud.google.com/firestore/docs)
- [Firestore Pricing](https://cloud.google.com/firestore/pricing)
- [Firestore Security Rules](https://cloud.google.com/firestore/docs/security/get-started)
- [Choosing a Database: Firestore vs. Bigtable vs. Cloud SQL](https://cloud.google.com/firestore/docs/choosing-storage-option)
- [google_firestore_database](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database)
