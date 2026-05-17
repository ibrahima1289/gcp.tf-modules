# GCP VM — Terraform Module

> Back to [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)

Terraform module for [Google Compute Engine (GCE)](https://cloud.google.com/compute/docs) that creates one or many VM instances with fully configurable machine types, boot disks, additional data disks, networking, service accounts, scheduling (including Spot VMs), Shielded VM, and metadata. All entries are optional via `create = optional(bool, true)`.

---

## Architecture

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                        VM Instance (per entry)                           │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │  Compute Engine Instance                                          │   │
│  │                                                                   │   │
│  │  Machine Type: e2-medium / n2-standard-4 / c2-standard-8 / ...    │   │
│  │  Zone:         us-central1-a / us-east1-b / ...                   │   │
│  │                                                                   │   │
│  │  ┌──────────────┐   ┌─────────────────────────────────────────┐   │   │
│  │  │  Boot Disk   │   │         Data Disks (optional, N)        │   │   │
│  │  │  pd-balanced │   │  pd-balanced / pd-ssd / hyperdisk-*     │   │   │
│  │  │  debian-12   │   │  Separate lifecycle from instance       │   │   │
│  │  └──────────────┘   └─────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  ┌────────────────────────────────────────────────────────────┐   │   │
│  │  │  Network Interface                                         │   │   │
│  │  │  VPC Network · Subnetwork                                  │   │   │
│  │  │  External IP (ephemeral / static / none)                   │   │   │
│  │  └────────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  ┌────────────────────┐   ┌───────────────────────────────────┐   │   │
│  │  │  Service Account   │   │  Scheduling                       │   │   │
│  │  │  Custom or default │   │  Standard / Spot (preemptible)    │   │   │
│  │  │  cloud-platform    │   │  MIGRATE / TERMINATE              │   │   │
│  │  └────────────────────┘   └───────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  ┌─────────────────────────────────────────────────────────────┐  │   │
│  │  │  Shielded VM (optional)                                     │  │   │
│  │  │  Secure Boot · vTPM · Integrity Monitoring                  │  │   │
│  │  └─────────────────────────────────────────────────────────────┘  │   │
│  └───────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  Step 1: google_compute_instance   (keyed by vm.key)                     │
│  Step 2: google_compute_disk       (keyed by "<vm_key>/<disk_name>")     │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Resources Created

| Step | Resource | Purpose |
|------|----------|---------|
| 1 | [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | VM instance with boot disk, networking, scheduling, and metadata |
| 2 | [`google_compute_disk`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | Additional data disks with independent lifecycle |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.5` |
| Google Provider | `>= 6.0` |

### IAM required

| Role | Scope |
|------|-------|
| `roles/compute.instanceAdmin.v1` | Project |
| `roles/iam.serviceAccountUser` | Project (to attach service accounts) |
| `roles/compute.networkUser` | Project (for shared VPC subnetworks) |

---

## Usage

### Example 1 — Simple web server

```hcl
module "gcp_vm" {
  source     = "../../modules/compute/gcp_vm"
  project_id = "my-project"
  region     = "us-central1"

  vms = [
    {
      key          = "web-01"
      name         = "web-server-01"
      zone         = "us-central1-a"
      machine_type = "e2-medium"
      image        = "debian-cloud/debian-12"
      disk_size_gb = 20
      network      = "default"
      network_tags = ["http-server", "https-server"]
      startup_script = "apt-get update && apt-get install -y nginx && systemctl start nginx"
    }
  ]

  tags = { env = "dev", team = "platform" }
}
```

### Example 2 — Multiple VMs with data disks and no external IP

```hcl
module "gcp_vm" {
  source     = "../../modules/compute/gcp_vm"
  project_id = "my-project"
  region     = "us-central1"

  vms = [
    {
      key          = "db-01"
      name         = "db-server-01"
      zone         = "us-central1-a"
      machine_type = "n2-standard-4"
      image        = "debian-cloud/debian-12"
      disk_size_gb = 50
      disk_type    = "pd-ssd"
      external_ip  = false
      network      = "projects/my-project/global/networks/prod-vpc"
      subnetwork   = "projects/my-project/regions/us-central1/subnetworks/prod-db"
      network_tags = ["db-server"]
      service_account_email = "db-sa@my-project.iam.gserviceaccount.com"

      data_disks = [
        {
          name    = "db-data-disk"
          size_gb = 500
          type    = "pd-ssd"
        }
      ]

      deletion_protection = true
    },
    {
      key          = "db-02"
      name         = "db-server-02"
      zone         = "us-central1-b"
      machine_type = "n2-standard-4"
      image        = "debian-cloud/debian-12"
      disk_size_gb = 50
      disk_type    = "pd-ssd"
      external_ip  = false
      network      = "projects/my-project/global/networks/prod-vpc"
      subnetwork   = "projects/my-project/regions/us-central1/subnetworks/prod-db"
      network_tags = ["db-server"]

      data_disks = [
        {
          name    = "db-data-disk-2"
          size_gb = 500
          type    = "pd-ssd"
        }
      ]

      deletion_protection = true
    }
  ]

  tags = { env = "prod", team = "data" }
}
```

### Example 3 — Spot VM batch worker with Shielded VM

```hcl
module "gcp_vm" {
  source     = "../../modules/compute/gcp_vm"
  project_id = "my-project"
  region     = "us-central1"

  vms = [
    {
      key          = "batch-worker"
      name         = "batch-worker-01"
      zone         = "us-central1-c"
      machine_type = "e2-standard-8"
      image        = "debian-cloud/debian-12"
      spot         = true

      enable_shielded_vm   = true
      enable_secure_boot   = true
      enable_vtpm          = true
      enable_integrity_mon = true

      metadata = {
        batch-job-id = "job-2026-001"
      }
    }
  ]

  tags = { env = "batch", team = "data-eng" }
}
```

---

## Variables

### Common

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `project_id` | `string` | — | ✅ | GCP project ID |
| `region` | `string` | `us-central1` | ❌ | Default region |
| `tags` | `map(string)` | `{}` | ❌ | Governance labels applied to all VMs |

---

### `vms[]` — instance fields

| Field | Type | Default | Required | Description |
|-------|------|---------|:--------:|-------------|
| `key` | `string` | — | ✅ | Unique stable map key |
| `create` | `bool` | `true` | ❌ | Set `false` to skip creation |
| `name` | `string` | — | ✅ | GCE instance resource name |
| `zone` | `string` | — | ✅ | Zone where the instance is created |
| `machine_type` | `string` | `e2-medium` | ❌ | GCE machine type |
| `image` | `string` | `debian-cloud/debian-12` | ❌ | Boot disk source image |
| `disk_size_gb` | `number` | `20` | ❌ | Boot disk size in GB |
| `disk_type` | `string` | `pd-balanced` | ❌ | Boot disk type |
| `keep_disk` | `bool` | `false` | ❌ | Set `true` to keep boot disk on destroy |
| `network` | `string` | `default` | ❌ | VPC network name or self-link |
| `subnetwork` | `string` | `""` | ❌ | Subnetwork name or self-link |
| `external_ip` | `bool` | `true` | ❌ | Assign an external IP address |
| `static_ip` | `string` | `""` | ❌ | Reserved external IP self-link (overrides ephemeral) |
| `network_tags` | `list(string)` | `[]` | ❌ | GCE network tags for firewall targeting |
| `service_account_email` | `string` | `""` | ❌ | Service account email. Empty = Compute Engine default SA |
| `service_account_scopes` | `list(string)` | `[cloud-platform]` | ❌ | OAuth scopes for the SA |
| `spot` | `bool` | `false` | ❌ | Use Spot VM (preemptible, auto-restart disabled) |
| `allow_stopping_for_update` | `bool` | `true` | ❌ | Allow Terraform to stop VM for in-place changes |
| `automatic_restart` | `bool` | `true` | ❌ | Auto-restart on infrastructure events (disabled for Spot) |
| `on_host_maintenance` | `string` | `MIGRATE` | ❌ | `MIGRATE` or `TERMINATE` during maintenance |
| `startup_script` | `string` | `""` | ❌ | Shell script run at first boot |
| `metadata` | `map(string)` | `{}` | ❌ | Arbitrary metadata key/value pairs |
| `enable_shielded_vm` | `bool` | `false` | ❌ | Enable Shielded VM features |
| `enable_secure_boot` | `bool` | `false` | ❌ | Enable Secure Boot (requires `enable_shielded_vm`) |
| `enable_vtpm` | `bool` | `true` | ❌ | Enable vTPM (requires `enable_shielded_vm`) |
| `enable_integrity_mon` | `bool` | `true` | ❌ | Enable Integrity Monitoring (requires `enable_shielded_vm`) |
| `deletion_protection` | `bool` | `false` | ❌ | Prevent accidental deletion |
| `labels` | `map(string)` | `{}` | ❌ | Instance-level labels merged with common labels |

---

### `vms[].data_disks[]` — additional disk fields

| Field | Type | Default | Required | Description |
|-------|------|---------|:--------:|-------------|
| `name` | `string` | — | ✅ | Disk resource name |
| `size_gb` | `number` | `50` | ❌ | Disk size in GB |
| `type` | `string` | `pd-balanced` | ❌ | Disk type |
| `device_name` | `string` | `""` | ❌ | Device name inside the OS. Defaults to `name` |
| `auto_delete` | `bool` | `true` | ❌ | Delete disk when instance is destroyed |

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_ids` | Instance resource IDs, keyed by `vm.key` |
| `instance_names` | Instance resource names, keyed by `vm.key` |
| `instance_self_links` | Self-links of all VM instances, keyed by `vm.key` |
| `instance_zones` | Zone of each instance, keyed by `vm.key` |
| `internal_ips` | Internal IP addresses, keyed by `vm.key` |
| `external_ips` | External (NAT) IP addresses, keyed by `vm.key`. Empty string if no external IP |
| `data_disk_ids` | Data disk IDs, keyed by `<vm_key>/<disk_name>` |
| `data_disk_self_links` | Data disk self-links, keyed by `<vm_key>/<disk_name>` |
| `common_labels` | Merged governance labels applied to all resources |

---

## Notes

- **Stable state keys**: Instances use `vm.key` as the `for_each` key, so reordering entries in `terraform.tfvars` never destroys and recreates resources.
- **Spot VMs**: Setting `spot = true` automatically sets `preemptible = true`, disables `automatic_restart`, and sets `on_host_maintenance = TERMINATE`. Use for fault-tolerant batch workloads.
- **Data disks**: Created as separate `google_compute_disk` resources so they persist when an instance is destroyed and re-created. Keyed by `<vm_key>/<disk_name>`.
- **No external IP**: Set `external_ip = false` for internal-only instances. Use Cloud NAT for outbound internet access.
- **Shielded VM**: Requires a [Shielded VM-compatible image](https://cloud.google.com/compute/shielded-vm/docs/shielded-vm#supported-images). Works with all Debian, Ubuntu, RHEL, CentOS, and Windows images.
- **Deletion protection**: Set `deletion_protection = true` in production to block `terraform destroy` and accidental Console deletions.
