# Google Cloud CDN

## Service overview

[Google Cloud CDN](https://cloud.google.com/cdn/docs) is a globally distributed content delivery network built on Google's edge infrastructure. It caches HTTP responses at edge PoPs (Points of Presence) close to users, reducing latency and offloading traffic from your origin backends. Cloud CDN works exclusively with the global external Application Load Balancer and is not a standalone service.

---

## How Cloud CDN works

```text
User (browser/client)
  └── DNS → Global Anycast IP → Nearest Google Edge PoP
        ├── Cache HIT → response served from edge (low latency, no origin cost)
        └── Cache MISS → request forwarded to origin backend
              └── Origin response cached at edge per cache-control headers
```

- **Cache key**: by default, the request URL (scheme + host + path + query string)
- **TTL**: controlled by `Cache-Control: max-age` or `s-maxage` in origin response headers
- **Invalidation**: purge individual URLs or URL prefixes manually or via API

---

## Cache modes

| Mode | Description | When to use |
|------|-------------|-------------|
| `USE_ORIGIN_HEADERS` | Cache only when origin sends `Cache-Control: public` | Default; respects origin caching intent |
| `CACHE_ALL_STATIC` | Cache all static content by file extension, even without explicit headers | Origins that don't set cache headers on static assets |
| `FORCE_CACHE_ALL` | Cache all successful responses (200, 203, 206, etc.) regardless of headers | High-cache environments; bypass origin intent |

---

## Origin backend types

| Backend type | Cloud CDN support |
|-------------|:-----------------:|
| Managed Instance Group (MIG) | ✅ |
| Unmanaged Instance Group | ✅ |
| Network Endpoint Group (NEG) | ✅ |
| GCS bucket (backend bucket) | ✅ |
| Cloud Run / App Engine (via NEG) | ✅ |

---

## Cache key customization

| Option | Description |
|--------|-------------|
| **Include/exclude query params** | Cache different versions by query parameter values |
| **Include HTTP headers** | Vary cache by request header (e.g., `Accept-Language`) |
| **Include named cookies** | Cache separate entries per cookie value |
| **Strip query string** | Cache one entry for all query variations of a URL |

---

## Signed URLs and signed cookies

| Feature | Description | Use case |
|---------|-------------|----------|
| **Signed URLs** | Time-limited URL with HMAC signature | Paid content, temporary download links |
| **Signed cookies** | Cookie-based access control for multiple objects | Video streaming sessions, authenticated content |

---

## When to use Cloud CDN

- Users are globally distributed and need low-latency responses.
- Responses include cacheable static or semi-static content (HTML, JS, CSS, images, videos).
- Origin infrastructure needs traffic offload during peak load.
- You serve large binary files (software downloads, media assets).

---

## Core capabilities

- Edge caching at 100+ Google PoPs worldwide.
- Integration with global external Application Load Balancer.
- Configurable cache modes: origin-controlled, static-auto, or force-all.
- Custom cache keys for query parameters, headers, and cookies.
- Signed URL and signed cookie support for access-controlled content.
- Cache invalidation API for on-demand purge.

---

## Real-world usage

- Global e-commerce and marketing websites with high static asset volume.
- Video streaming platforms offloading large file delivery from origin.
- SaaS application frontends with aggressive caching for JS/CSS bundles.
- API response acceleration for cacheable GET endpoints.
- Software distribution and large file download optimization.

---

## Security and operations guidance

- Use signed URLs or signed cookies to protect premium, paid, or private content.
- Define explicit cache policies by path — do not cache API responses with user-specific data.
- Track cache hit ratio (`loadbalancing.googleapis.com/https/external/egress_ratio`); tune TTL and cache mode.
- Invalidate cache after deployments that change static assets.
- Combine with Cloud Armor for edge DDoS protection and WAF rules in front of cached content.
- Enable HTTPS-only and enforce HSTS headers on cached responses.

---

## Terraform resources commonly used

| Resource | Purpose |
|----------|---------|
| [`google_compute_backend_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | Enable CDN with `enable_cdn = true` and configure `cdn_policy` |
| [`google_compute_backend_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket) | Serve GCS bucket content through CDN |
| [`google_compute_url_map`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | Route paths to CDN-enabled backends |

---

## Related Docs

- [Cloud CDN Overview](https://cloud.google.com/cdn/docs)
- [Cache Modes](https://cloud.google.com/cdn/docs/caching)
- [Signed URLs](https://cloud.google.com/cdn/docs/signed-urls)
- [Cloud Load Balancing (required)](../gcp_cloud_load_balancer/gcp-cloud-load-balancer.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
