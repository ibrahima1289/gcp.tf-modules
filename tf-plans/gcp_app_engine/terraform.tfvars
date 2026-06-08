# terraform.tfvars

# ---------------------------------------------------------------------------
# Default project and region
# ---------------------------------------------------------------------------
project_id = "main-project-456789"
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
# App Engine application — singleton per GCP project.
# location_id is permanent after the first apply; cannot be changed.
# ---------------------------------------------------------------------------
application = {
  location_id    = "us-central"
  serving_status = "SERVING"
  database_type  = "CLOUD_FIRESTORE"

  # Uncomment to enable Identity-Aware Proxy for zero-trust access control.
  # iap_enabled              = true
  # iap_oauth2_client_id     = "123456789-abc.apps.googleusercontent.com"
  # iap_oauth2_client_secret = "<secret>"
}

# ---------------------------------------------------------------------------
# Service version definitions
# ---------------------------------------------------------------------------
services = [

  # ── Standard Python web service (default service, automatic scaling) ───────
  # Deploys a Python 3.12 app from a GCS ZIP. Scales to zero when idle.
  # noop_on_destroy = true (default) means the version persists after destroy.
  {
    key        = "default-web"
    service    = "default"
    runtime    = "python312"
    version_id = "v1"
    env_type   = "standard"

    deployment_type           = "zip"
    deployment_zip_source_url = "https://storage.googleapis.com/my-project-deploy/web-app.zip"

    entrypoint_shell = "exec gunicorn"

    # Automatic scaling — scale to zero with max 5 instances.
    scaling_type           = "automatic"
    min_instances          = 0
    max_instances          = 5
    target_cpu_utilization = 0.6

    instance_class = "F2"

    env_variables = {
      LOG_LEVEL = "INFO"
      APP_ENV   = "production"
    }

    create = true
  },

  # ── Standard Node.js API service (basic scaling for cost-efficiency) ────────
  # Uses F2 instance class for higher concurrency. Basic scaling shuts instances
  # down after idle_timeout, making it cheaper than auto for irregular traffic.
  {
    key        = "api-service"
    service    = "api"
    runtime    = "nodejs20"
    version_id = "v1"
    env_type   = "standard"

    deployment_type           = "zip"
    deployment_zip_source_url = "https://storage.googleapis.com/my-project-deploy/api-app.zip"

    entrypoint_shell = "node app.js"

    # Basic scaling — cheaper for low/irregular traffic; max 3 instances.
    scaling_type                = "basic"
    basic_scaling_idle_timeout  = "10m"
    basic_scaling_max_instances = 3

    instance_class = "F2"

    env_variables = {
      NODE_ENV = "production"
      PORT     = "8080"
    }

    create = true
  },

  # ── Flexible environment worker using a container image ─────────────────────
  # Runs a custom Docker image from Artifact Registry. Flexible does not
  # scale to zero; min_instances = 1 keeps a warm instance always running.
  {
    key        = "worker-flex"
    service    = "worker"
    runtime    = "custom" # custom = bring your own Dockerfile
    version_id = "v1"
    env_type   = "flexible"

    deployment_type            = "container"
    deployment_container_image = "us-docker.pkg.dev/my-project-id/my-repo/worker:latest"

    # Compute resources per instance.
    resources_cpu       = 1
    resources_disk_gb   = 10
    resources_memory_gb = 1.0

    # Health checks — required for flexible environment.
    liveness_check_path  = "/health"
    readiness_check_path = "/ready"

    # Automatic scaling — keep 1 warm instance, scale up to 5 on load.
    scaling_type           = "automatic"
    min_instances          = 1
    max_instances          = 5
    target_cpu_utilization = 0.7

    env_variables = {
      WORKER_THREADS = "4"
      QUEUE_URL      = "https://pubsub.googleapis.com/v1/projects/my-project-id/topics/jobs"
    }

    create = true
  },

  # ── Disabled entry kept for safe toggling without config removal ─────────────
  {
    key        = "legacy-php"
    service    = "legacy"
    runtime    = "php83"
    version_id = "v1"
    env_type   = "standard"

    deployment_type           = "zip"
    deployment_zip_source_url = "https://storage.googleapis.com/my-project-deploy/legacy.zip"

    create = false # skipped — no resources created
  },

]

# ---------------------------------------------------------------------------
# Firewall rules — restrict inbound access to the application.
# Rules are evaluated in ascending priority order (lowest number wins).
# ---------------------------------------------------------------------------
firewall_rules = [
  # Allow traffic from a trusted corporate CIDR range.
  {
    key          = "allow-corp"
    priority     = 100
    action       = "ALLOW"
    source_range = "203.0.113.0/24"
    description  = "Allow corporate network"
    create       = true
  },
  # Default allow-all — remove or replace with a DENY rule for restricted apps.
  {
    key          = "allow-all"
    priority     = 1000
    action       = "ALLOW"
    source_range = "*"
    description  = "Default allow all"
    create       = true
  },
]

# ---------------------------------------------------------------------------
# Domain mappings — custom domains served by this application.
# After apply: add dns_records output values to your DNS provider.
# ---------------------------------------------------------------------------
domain_mappings = []

# ---------------------------------------------------------------------------
# URL dispatch rules — route requests to specific services by path/domain.
# ---------------------------------------------------------------------------
dispatch_rules = [
  {
    domain  = "*"
    path    = "/api/*"
    service = "api"
  },
  {
    domain  = "*"
    path    = "/*"
    service = "default"
  },
]
