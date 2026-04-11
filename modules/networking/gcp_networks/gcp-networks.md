# Google Cloud Networks (VPC): What They Are and Real-World Usage

## What is a Google Cloud network?

A **Google Cloud VPC network** is the private network boundary for your workloads.

In simple terms:

- A **VPC network** is the global network container.
- **Subnetworks** are regional IP segments inside that VPC.
- Compute resources (VMs, GKE nodes, internal load balancers, private services) attach to subnetworks, not directly to the top-level VPC.

Reference: [Google Cloud VPC overview](https://cloud.google.com/vpc/docs/vpc)

---

## Where networks fit in the GCP hierarchy

Typical resource flow:

**Organization / Folder / Project → VPC Network → Subnetwork → Workloads**

This means network design is a key control point for:

- IP planning
- east-west traffic paths
- internet egress strategy
- hybrid connectivity
- security boundaries

---

## Core capabilities of VPC networks

## 1) Global network scope

Unlike many cloud providers, Google Cloud VPC networks are **global**.

You can host subnets in multiple regions under one VPC and control routing with:

- `REGIONAL` routing mode
- `GLOBAL` routing mode

---

## 2) Custom-mode vs auto-mode networks

- **Custom mode (recommended):** you define subnet CIDRs and regions intentionally.
- **Auto mode:** Google creates one subnet per region using predefined ranges.

For production landing zones, custom mode is usually preferred for predictable IP governance.

---

## 3) Shared VPC

You can centralize networking in a host project and attach service projects.

This is widely used when:

- platform teams own networking
- app teams own workloads
- central policy, firewall, and connectivity controls are required

Reference: [Shared VPC overview](https://cloud.google.com/vpc/docs/shared-vpc)

---

## 4) Security and policy enforcement

Network structure supports better control of:

- firewall rule boundaries
- hierarchical policy strategy
- route domain clarity
- blast-radius isolation

Good network separation reduces accidental lateral movement and simplifies audits.

---

## 5) Advanced network options

Common options used in real environments:

- custom `mtu` tuning for specific connectivity patterns
- `delete_default_routes_on_create` for controlled egress design
- internal IPv6 ULA enablement
- firewall policy enforcement order selection

---

## Real-world usage patterns

## 1) Single-team application foundation

**Scenario:** One product team runs dev and prod workloads in one project.

Pattern:

- `app-dev-vpc`
- `app-prod-vpc`

Why this works:

- clean environment isolation
- straightforward firewall and route policy
- lower operational confusion

---

## 2) Enterprise Shared VPC model

**Scenario:** A central cloud platform team provides core networking for many app teams.

Pattern:

- one host project with shared VPC network(s)
- multiple service projects attached

Why this works:

- centralized control with delegated app ownership
- reusable security baselines
- consistent outbound and hybrid connectivity model

---

## 3) Multi-region service deployment

**Scenario:** A customer-facing service runs in multiple regions.

Pattern:

- one VPC network
- regional subnets (e.g., `us-central1`, `us-east1`, `europe-west1`)
- routing mode selected based on latency and failover goals

Why this works:

- unified network domain
- easier cross-region architecture governance
- supports resilient deployment patterns

---

## 4) Regulated workload isolation

**Scenario:** Compliance requires strong segmentation between regulated and non-regulated workloads.

Pattern:

- dedicated VPC for regulated systems
- separate VPC for general workloads
- strict peering/shared services policy

Why this works:

- clear control boundaries
- simpler evidence for audits
- reduced risk of policy drift

---

## 5) Private data platform

**Scenario:** Analytics/ETL pipelines run with no public IPs.

Pattern:

- private subnets in a dedicated VPC
- controlled egress via NAT/proxy design
- private service communication patterns

Why this works:

- stronger security posture
- less public exposure
- deterministic outbound controls

---

## Practical design recommendations

- Prefer **custom-mode VPCs** for production.
- Plan CIDRs early to avoid future overlap.
- Use naming conventions that encode environment, purpose, and region.
- Separate high-risk/high-compliance workloads into dedicated network domains.
- Keep routing and firewall intent simple and explicit.
- Use Shared VPC when many teams consume a common network platform.

---

## Common mistakes to avoid

- Treating VPC as “just plumbing” and skipping architecture planning.
- Overloading one network with unrelated workload types.
- Using auto-mode networks in environments requiring strict IP governance.
- Leaving default routes in place when egress should be tightly controlled.
- Not defining ownership boundaries between platform and application teams.

---

## Related Docs

- [GCP VPC Module README](README.md)
- [GCP Subnet Module README](../gcp_subnet/README.md)
- [GCP Subnetworks Practical Guide](../gcp_subnetworks/gcp-subnetworks.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud VPC Overview](https://cloud.google.com/vpc/docs/vpc)
- [Shared VPC Overview](https://cloud.google.com/vpc/docs/shared-vpc)
