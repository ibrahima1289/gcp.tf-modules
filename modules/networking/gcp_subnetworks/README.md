# GCP Subnet Terraform Module

Manages one or many [Google Cloud VPC subnets](https://cloud.google.com/vpc/docs/subnets) with optional private Google access, secondary IP ranges, and VPC Flow Logs.

---

## Architecture

```text
+---------------------------------------------------------------+
| Input defaults                                                |
| project_id, network, region, labels                           |
+-------------------------------+-------------------------------+
                                |
                                v
+---------------------------------------------------------------+
| local.resolved_subnets_map                                    |
| applies per-subnet overrides for project, network, and region |
+-------------------------------+-------------------------------+
                                |
                                v
+---------------------------------------------------------------+
| google_compute_subnetwork (for_each)                          |
| - primary CIDR                                                |
| - secondary IP ranges                                         |
| - private Google access                                       |
| - optional flow logs                                          |
+---------------------------------------------------------------+
```

---

## Requirements

| Requirement | Version / Note |
|---|---|
| Terraform | `>= 1.5` |
| Provider | `hashicorp/google >= 6.0` |
| Auth | Application Default Credentials (ADC) or Workload Identity Federation |
| Parent network | Existing VPC network name or self link |

---

## Resources Managed

| Resource | Purpose |
|---|---|
| `google_compute_subnetwork` | Creates one or many regional subnets |

---

## Required Variables

| Name | Type | Description |
|---|---|---|
| `subnets` | `list(object)` | List of subnet definitions to create. Each requires `key`, `name`, and `ip_cidr_range`. |
| `project_id` or per-subnet `project_id` | `string` | Set a module default project or provide project per subnet. |
| `network` or per-subnet `network` | `string` | Set a module default network or provide network per subnet. |

---

## Optional Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-central1` | Default region for subnets without region override |
| `project_id` | `string` | `""` | Default project ID applied to subnet entries |
| `network` | `string` | `""` | Default VPC network name or self link |
| `labels` | `map(string)` | `{}` | Metadata labels tracked in locals/outputs |

### `subnets` object fields

| Field | Required | Description |
|---|---|---|
| `key` | Yes | Stable key for `for_each` |
| `name` | Yes | Subnet name |
| `ip_cidr_range` | Yes | Primary subnet CIDR block |
| `project_id` | No | Project override |
| `network` | No | VPC network override |
| `region` | No | Region override |
| `description` | No | Subnet description |
| `private_ip_google_access` | No | Enable private Google access |
| `purpose` | No | Subnet purpose |
| `stack_type` | No | IPv4-only or dual-stack |
| `secondary_ip_ranges` | No | Secondary CIDR ranges for GKE/services |
| `log_config` | No | Optional VPC Flow Logs configuration |

---

## Outputs

| Name | Description |
|---|---|
| `subnet_self_links` | Map of subnet key to self link |
| `subnet_names` | Map of subnet key to subnet name |
| `subnet_regions` | Map of subnet key to effective region |
| `subnet_cidr_ranges` | Map of subnet key to primary CIDR range |
| `subnet_gateway_addresses` | Map of subnet key to gateway address |
| `subnet_private_google_access` | Map of subnet key to private Google access status |
| `common_labels` | Metadata labels merged with `created_date` and `managed_by` |

---

## Usage

```hcl
module "subnet" {
  source = "../../modules/networking/gcp_subnet"

  # Step 1: shared defaults.
  project_id = "example-network-prj"
  network    = "shared-vpc"
  region     = "us-central1"

  # Step 2: create one or many subnets.
  subnets = [
    {
      key                      = "apps-central"
      name                     = "apps-central"
      ip_cidr_range            = "10.10.0.0/24"
      private_ip_google_access = true
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.20.0.0/20"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.30.0.0/24"
        }
      ]
      log_config = {
        enabled              = true
        aggregation_interval = "INTERVAL_5_SEC"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  ]

  # Step 3: metadata labels.
  labels = {
    environment = "shared"
    owner       = "network-team"
  }
}
```

---

## Validation & Behavior

- Supports one or many subnets with stable `key` values.
- Requires project and network to resolve either globally or per subnet.
- Avoids null-driven configuration by using concrete defaults and dynamic blocks only where needed.
- Secondary ranges and flow logs are optional and created only when explicitly configured.
- Uses region defaults with per-subnet override support for safer scale-out.

---

## Related Docs

- [GCP Subnetworks Deployment Plan](../../../tf-plans/gcp_subnetworks/README.md)
- [GCP Cloud NAT Module](../gcp_cloud_nat/README.md)
- [GCP Cloud NAT Deployment Plan](../../../tf-plans/gcp_cloud_nat/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud Services Pricing Guide](../../../gcp-services-pricing-guide.md)
- [Terraform Deployment Guide](../../../gcp-terraform-deployment-cli-github-actions.md)
