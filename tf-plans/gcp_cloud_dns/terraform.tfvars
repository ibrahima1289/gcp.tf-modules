# terraform.tfvars

# ---------------------------------------------------------------------------
# Default placement
# ---------------------------------------------------------------------------
project_id = "main-project-492903"
region     = "us-central1"

# ---------------------------------------------------------------------------
# Common governance tags
# ---------------------------------------------------------------------------
tags = {
  owner       = "platform-team"
  environment = "production"
  team        = "platform"
}

# ---------------------------------------------------------------------------
# One or many DNS zone definitions with nested record sets
# ---------------------------------------------------------------------------
zones = [

  # ── Public zone with DNSSEC and multiple record types ──────────────────────
  # DNSSEC is enabled; update your registrar's DS records after apply.
  # zone_name_servers output contains the NS values needed for delegation.
  {
    key            = "example-public"
    name           = "example-com-public"
    dns_name       = "example.com."
    description    = "Primary public zone for example.com"
    zone_type      = "public"
    dnssec_enabled = true

    records = [
      # Apex A record pointing to the load balancer IP.
      {
        key     = "apex-a"
        name    = "example.com."
        type    = "A"
        ttl     = 300
        rrdatas = ["34.120.0.1"]
      },
      # CNAME for www redirecting to apex.
      {
        key     = "www-cname"
        name    = "www.example.com."
        type    = "CNAME"
        ttl     = 300
        rrdatas = ["example.com."]
      },
      # MX records for Google Workspace mail routing.
      {
        key     = "mx"
        name    = "example.com."
        type    = "MX"
        ttl     = 3600
        rrdatas = ["1 aspmx.l.google.com.", "5 alt1.aspmx.l.google.com."]
      },
      # SPF TXT record for mail sender verification.
      {
        key     = "spf"
        name    = "example.com."
        type    = "TXT"
        ttl     = 3600
        rrdatas = ["\"v=spf1 include:_spf.google.com ~all\""]
      },
      # API endpoint using weighted round-robin for gradual traffic split.
      {
        key  = "api-wrr"
        name = "api.example.com."
        type = "A"
        ttl  = 60
        routing_policy = {
          enabled            = true
          type               = "WRR"
          enable_geo_fencing = false
          wrr_targets = [
            { weight = 0.8, rrdatas = ["34.120.0.1"] },
            { weight = 0.2, rrdatas = ["34.120.0.2"] },
          ]
          geo_targets = []
        }
      },
    ]

    create = true
  },

  # ── Private zone bound to a VPC for internal service resolution ────────────
  # Not internet-resolvable; only the listed VPC can query this zone.
  {
    key         = "internal-private"
    name        = "internal-example-com"
    dns_name    = "internal.example.com."
    description = "Private zone for internal service discovery"
    zone_type   = "private"

    private_visibility_networks = [
      "projects/main-project-492903/global/networks/my-vpc"
    ]

    records = [
      # Internal API endpoint.
      {
        key     = "api-internal"
        name    = "api.internal.example.com."
        type    = "A"
        ttl     = 60
        rrdatas = ["10.0.1.5"]
      },
      # Internal database endpoint.
      {
        key     = "db-internal"
        name    = "db.internal.example.com."
        type    = "A"
        ttl     = 60
        rrdatas = ["10.0.1.20"]
      },
    ]

    create = true
  },

  # ── Forwarding zone delegating on-prem domain queries to on-prem DNS ───────
  # Queries for corp.example.com are forwarded to the on-prem resolver.
  # private forwarding_path sends queries through the VPC rather than the internet.
  {
    key         = "onprem-forwarding"
    name        = "corp-example-com"
    dns_name    = "corp.example.com."
    description = "Forwarding zone for on-prem corporate domain"
    zone_type   = "forwarding"

    private_visibility_networks = [
      "projects/main-project-492903/global/networks/my-vpc"
    ]

    forwarding_targets = [
      { ipv4_address = "192.168.1.100", forwarding_path = "private" },
      { ipv4_address = "192.168.1.101", forwarding_path = "private" },
    ]

    create = true
  },

  # ── Disabled entry retained for safe rollout toggles ───────────────────────
  {
    key       = "legacy-zone"
    name      = "legacy-example-com"
    dns_name  = "legacy.example.com."
    zone_type = "public"
    create    = false # skipped — no resources created
  },

]
