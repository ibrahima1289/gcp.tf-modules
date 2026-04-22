# GCP Cloud VPN — Deployment Plan

> Module: [modules/networking/gcp_cloud_vpn](../../modules/networking/gcp_cloud_vpn/README.md)
> Back to: [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)

This deployment plan wires the `gcp_cloud_vpn` module to a real GCP project. Edit `terraform.tfvars` to configure peer gateways and HA VPN gateways, then run the standard Terraform workflow.

---

## File Structure

```text
tf-plans/gcp_cloud_vpn/
├── main.tf           # module call — peers + gateways
├── variables.tf      # mirrors module variable definitions
├── locals.tf         # created_date timestamp
├── outputs.tf        # pass-through module outputs
├── providers.tf      # Google provider + optional GCS backend
├── terraform.tfvars  # example values — customize before applying
└── README.md         # this file
```

---

## Prerequisites

1. **Terraform** `>= 1.5` installed.
2. A GCP project with the **Compute Engine API** enabled (`compute.googleapis.com`).
3. A **Cloud Router** already provisioned in the same region and VPC. Use the [Cloud Router module](../gcp_cloud_router/README.md).
4. Caller has `roles/compute.networkAdmin` or an equivalent custom role.
5. The on-premises (or other-cloud) device public IPs must be known before applying.
6. Pre-shared keys should be stored in **Secret Manager** and injected at plan time — do not commit real keys to source control.

---

## Apply Workflow

```bash
cd tf-plans/gcp_cloud_vpn

# 1. Authenticate
gcloud auth application-default login

# 2. Initialise providers and backend
terraform init

# 3. Review planned changes
terraform plan -var-file=terraform.tfvars

# 4. Apply
terraform apply -var-file=terraform.tfvars

# 5. Retrieve the GCP external IPs to configure the peer device
terraform output ha_gateway_vpn_interfaces
```

---

## Post-Apply: Configure the Peer Device

After `terraform apply`, run:

```bash
terraform output ha_gateway_vpn_interfaces
```

The output maps each gateway key to its two allocated external IP addresses. Provide these IPs to your network team to configure the peer firewall/router.

Minimum peer device configuration:
- IKEv2 (recommended) or IKEv1
- AES-256 + SHA-256 cipher suite
- Two IPsec tunnel definitions (one per GCP interface IP)
- BGP session with the `bgp_peer_ip` values from `terraform.tfvars` as the peer IPs and the Cloud Router's ASN as the remote ASN

---

## BGP Session Reference

Each tunnel requires a pair of link-local IPs from `169.254.0.0/16`. Use non-overlapping `/30` blocks:

| Tunnel | GCP BGP IP (router_bgp_ip_range) | Peer BGP IP (bgp_peer_ip) | Block |
|--------|----------------------------------|--------------------------|-------|
| Tunnel 0 | `169.254.1.1` | `169.254.1.2` | `169.254.1.0/30` |
| Tunnel 1 | `169.254.2.1` | `169.254.2.2` | `169.254.2.0/30` |
| Tunnel 2 | `169.254.3.1` | `169.254.3.2` | `169.254.3.0/30` |

---

## Shared Secret Management

Store pre-shared keys in Secret Manager and read them at plan time:

```bash
# Store a secret
gcloud secrets create vpn-tunnel-0-psk --replication-policy="automatic"
echo -n "myStrongSecret" | gcloud secrets versions add vpn-tunnel-0-psk --data-file=-

# Inject at plan time (avoid hardcoding in tfvars)
terraform plan \
  -var 'vpn_gateways=[{..., tunnels=[{shared_secret="'$(gcloud secrets versions access latest --secret vpn-tunnel-0-psk)'"...}]}]'
```

---

## Monitoring VPN Tunnel Health

After the VPN is up, create a Cloud Monitoring alert on:

```
metric.type = "vpn.googleapis.com/tunnel/established"
resource.type = "vpn_tunnel"
```

Alert when `established = 0` for more than 1 minute — indicates a tunnel is down.

---

## Peer Redundancy Type Reference

| `redundancy_type` | Peer Interfaces | Use Case |
|-------------------|----------------|---------|
| `SINGLE_IP_INTERNALLY_REDUNDANT` | 1 | Single device with internal redundancy |
| `TWO_IPS_REDUNDANCY` | 2 | Two edge devices or two WAN IPs — standard HA |
| `FOUR_IPS_REDUNDANCY` | 4 | AWS VGW, Azure VPN Gateway — 4 tunnel endpoints |

---

## Related Docs

- [Cloud VPN Module](../../modules/networking/gcp_cloud_vpn/README.md)
- [Cloud VPN Explainer](../../modules/networking/gcp_cloud_vpn/gcp-cloud-vpn.md)
- [Cloud Router Module](../../modules/networking/gcp_cloud_router/README.md)
- [Cloud Router Deployment Plan](../gcp_cloud_router/README.md)
- [GCP Module & Service Hierarchy](../../gcp-module-service-list.md)
- [HA VPN overview](https://cloud.google.com/network-connectivity/docs/vpn/concepts/ha-vpn)
- [Cloud VPN pricing](https://cloud.google.com/network-connectivity/docs/vpn/pricing)
