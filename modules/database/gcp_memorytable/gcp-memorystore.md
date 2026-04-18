# Google Memorystore (Redis / Valkey / Memcached)

[Memorystore](https://cloud.google.com/memorystore/docs) is a fully managed in-memory data store service on Google Cloud. It provides managed instances of **Redis**, **Valkey** (the Redis OSS fork), and **Memcached** — removing the operational burden of provisioning, patching, replication, and failover. Memorystore is commonly used as an application cache, session store, real-time leaderboard, pub/sub message broker, or rate-limiting backend.

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

---

## Overview

Memorystore instances run inside Google's infrastructure and are accessible only via **private IP** within a VPC (using Private Service Access). There is no public endpoint. Clients connect using the standard Redis or Memcached protocol — no code changes are required when migrating from self-managed instances.

| Capability | Redis / Valkey | Memcached |
|------------|---------------|-----------|
| **Data structures** | Strings, hashes, lists, sets, sorted sets, streams, geospatial, HyperLogLog | Simple key-value |
| **Persistence** | RDB snapshots + AOF (optional) | None (volatile) |
| **Replication** | Primary/replica pairs; automatic failover | None |
| **Cluster mode** | Sharded cluster up to 250 GB | Multi-node pool |
| **Pub/Sub** | ✅ | ❌ |
| **Lua scripting** | ✅ | ❌ |
| **IAM auth** | ✅ (AUTH string or IAM) | ❌ |
| **Private IP only** | ✅ | ✅ |

---

## Core Concepts

### Redis / Valkey Instance Tiers

| Tier | Description | Use Case |
|------|-------------|----------|
| **Basic** | Single node; no replication; no SLA | Development and non-critical caching |
| **Standard** | Primary + replica; automatic failover; 99.9% SLA | Production caching and session stores |
| **Cluster** | Sharded across multiple primary/replica shards; up to 250 GB; 99.9% SLA | Large datasets; high-throughput workloads |

### Valkey vs Redis

[Valkey](https://valkey.io) is the OSS fork of Redis maintained by the Linux Foundation after the Redis license change. Memorystore for Valkey is fully wire-compatible with Redis 7.2 — clients and tooling work unchanged.

### Memory Tiers and Sizing

Redis and Valkey instances are sized by memory allocation:

| Memory | Notes |
|--------|-------|
| 1 GB – 300 GB | Available in Standard tier |
| Up to 250 GB | Cluster mode across shards |

> Leave ~20–30% headroom for Redis overhead, AOF buffers, and replication lag.

### Persistence (Redis / Valkey)

| Mode | Description |
|------|-------------|
| **RDB snapshots** | Point-in-time snapshots; configurable interval; small performance impact |
| **AOF (Append-Only File)** | Every write logged; higher durability; higher write latency |
| **No persistence** | Fastest; data lost on restart; suitable for pure cache use cases |

### Connectivity

All Memorystore instances are accessible only within the same VPC via Private Service Access:

```text
App (VPC) ──── Private Service Access ────  Memorystore Instance (Google-managed VPC)
```

Configure the authorized network to the VPC where the application runs:

```hcl
resource "google_redis_instance" "cache" {
  name           = "my-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 4
  region         = "us-central1"

  authorized_network = "projects/my-project/global/networks/my-vpc"
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
}
```

---

## Common Use Cases

| Pattern | Description |
|---------|-------------|
| **Application cache** | Cache database query results; reduce backend load |
| **Session store** | HTTP session storage with TTL-based expiry |
| **Rate limiting** | `INCR` + `EXPIRE` for sliding window counters |
| **Leaderboard** | Sorted sets for real-time ranking |
| **Pub/Sub** | Lightweight message fan-out within a service |
| **Distributed lock** | `SET key value NX PX ttl` Redlock pattern |
| **Job queue** | `RPUSH` / `BLPOP` for simple task queues |
| **Geospatial indexing** | `GEOADD` / `GEORADIUS` for proximity searches |

---

## Memcached

Memcached is a simpler multi-threaded in-memory cache for pure key-value workloads:

| Setting | Description |
|---------|-------------|
| `node_count` | Number of nodes (1–20) |
| `memory_size_mb` | Memory per node (1024–65536 MB) |
| `cpu_count` | vCPUs per node (1–32) |

> Use Memcached when you need a simple, horizontally scaled cache and do not require Redis data structures, persistence, or pub/sub.

---

## Terraform Resources

```hcl
# Redis Standard (HA)
resource "google_redis_instance" "cache" {
  name               = "app-cache"
  tier               = "STANDARD_HA"
  memory_size_gb     = 8
  region             = "us-central1"
  redis_version      = "REDIS_7_2"
  authorized_network = "projects/my-project/global/networks/my-vpc"
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  auth_enabled       = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"
}

# Memcached
resource "google_memcache_instance" "cache" {
  name       = "app-memcache"
  region     = "us-central1"
  node_count = 3
  node_config {
    cpu_count      = 2
    memory_size_mb = 2048
  }
  authorized_network = "projects/my-project/global/networks/my-vpc"
}
```

---

## Security Guidance

- Enable **AUTH** (`auth_enabled = true`) on Redis instances to require a password.
- Enable **in-transit encryption** (`transit_encryption_mode = "SERVER_AUTHENTICATION"`) — requires TLS-capable client.
- Use **Private Service Access** — Memorystore has no public endpoint option.
- Grant `roles/redis.editor` to operators; `roles/redis.viewer` to read-only access; avoid `roles/redis.admin` in production.
- Rotate the AUTH string periodically using Secret Manager for storage.
- Monitor eviction rate (`evicted_keys`) — sustained evictions indicate under-provisioned memory.

---

## Related Docs

- [Memorystore for Redis Documentation](https://cloud.google.com/memorystore/docs/redis)
- [Memorystore for Valkey Documentation](https://cloud.google.com/memorystore/docs/valkey)
- [Memorystore for Memcached Documentation](https://cloud.google.com/memorystore/docs/memcached)
- [Memorystore Pricing](https://cloud.google.com/memorystore/pricing)
- [google_redis_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance)
- [google_memcache_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/memcache_instance)
