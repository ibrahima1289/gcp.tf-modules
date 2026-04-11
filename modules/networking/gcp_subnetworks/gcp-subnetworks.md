# Google Cloud Subnetworks: What They Are, What They Do, and Real-Life Uses

## What is a Subnetwork in Google Cloud?

A **subnetwork** (usually called a **subnet**) is a regional IP range inside a [Google Cloud VPC network](https://cloud.google.com/vpc/docs/vpc).

In simple terms:

- A **VPC network** is the overall private network boundary.
- A **subnetwork** is a smaller, structured segment inside that network where workloads live.

Subnetworks define:

- the IP address range available to resources
- the region where those resources are placed
- how internal connectivity is grouped and managed

---

## How subnetworks fit into Google Cloud networking

Google Cloud networking is commonly structured like this:

**Organization / Folder / Project → VPC Network → Subnetwork → Resources**

Resources such as the following are usually attached to subnetworks:

- Compute Engine VM instances
- GKE nodes and pods
- internal load balancers
- managed services with private IPs
- appliances and private service connectivity patterns

---

## What does a subnetwork do?

A subnetwork provides several important capabilities.

## 1) Defines IP space for workloads

Each subnet owns a CIDR range, such as `10.10.0.0/24`.

That range determines the private IP addresses available to resources in that subnet.

Example:

- `10.10.0.0/24` gives 256 total addresses in that subnet range

---

## 2) Places workloads in a specific region

Unlike a VPC network, which is global in Google Cloud, a **subnetwork is regional**.

Example:

- `apps-central` in `us-central1`
- `apps-europe` in `europe-west1`

This helps design low-latency, region-aware architectures.

---

## 3) Separates workloads logically

Subnetworks let you divide workloads by purpose.

Examples:

- frontend subnet
- backend subnet
- database subnet
- management subnet
- GKE pods/services subnet ranges

This improves readability, control, and operational safety.

---

## 4) Supports security and routing design

Firewall rules, routes, NAT, and private access patterns often depend on how subnetworks are organized.

For example:

- private application subnet with no public IPs
- database subnet restricted to application-tier traffic only
- admin subnet used only for bastion or management workloads

---

## 5) Enables private access to Google services

With **Private Google Access**, resources in a subnet without public IPs can still reach Google APIs and services privately.

This is common for:

- private VMs
- private GKE clusters
- secure data-processing workloads

---

## 6) Supports secondary IP ranges

Subnets can include **secondary IP ranges**, which are commonly used for:

- GKE Pods
- GKE Services
- service segmentation within the same subnet design

This is especially important in container-based environments.

---

## 7) Supports VPC Flow Logs

Subnetworks can enable **VPC Flow Logs** to capture traffic metadata for observability, troubleshooting, and security monitoring.

This helps answer questions like:

- Which workloads are talking to each other?
- Is unexpected traffic leaving the subnet?
- Are firewall and routing rules behaving as expected?

---

## Real-life examples

## 1) Three-tier application network

**Scenario:** A company runs a web application with frontend, backend, and database layers.

Subnets:

- `frontend-subnet` → public-facing application servers
- `backend-subnet` → internal APIs and app services
- `database-subnet` → private data layer

Why this helps:

- clean separation of tiers
- clearer firewall policy design
- easier troubleshooting and scaling

---

## 2) Shared VPC for many teams

**Scenario:** A central platform team operates a Shared VPC used by multiple product teams.

Subnets:

- `team-a-us-central1`
- `team-b-us-central1`
- `team-c-europe-west1`

Why this helps:

- each team gets dedicated address space
- central networking remains standardized
- shared controls can be enforced consistently

---

## 3) GKE private cluster design

**Scenario:** A company runs private Kubernetes clusters.

Subnet design:

- primary subnet range for GKE nodes
- secondary range for Pods
- secondary range for Services

Why this helps:

- clean IP planning for cluster growth
- avoids IP conflicts
- supports secure private cluster networking

---

## 4) Regional disaster recovery pattern

**Scenario:** A platform runs the same service in two regions.

Subnets:

- `apps-central` in `us-central1`
- `apps-east` in `us-east1`

Why this helps:

- regional isolation
- lower blast radius during outages
- simpler failover design

---

## 5) Private data processing environment

**Scenario:** ETL or analytics workloads run without public IPs.

Subnet settings:

- private instances only
- Private Google Access enabled
- Cloud NAT for internet-bound updates if required

Why this helps:

- stronger security posture
- less exposure to the public internet
- still allows access to Google-managed services

---

## Common design patterns

## Environment-based subnet layout

- `dev-subnet`
- `stage-subnet`
- `prod-subnet`

Useful when environments must stay isolated.

## Function-based subnet layout

- `web-subnet`
- `app-subnet`
- `data-subnet`

Useful for layered application design.

## Team-based subnet layout

- `payments-subnet`
- `analytics-subnet`
- `platform-subnet`

Useful for ownership clarity in shared platforms.

## Regional subnet layout

- `subnet-central`
- `subnet-east`
- `subnet-eu`

Useful for multi-region availability and locality.

---

## Best practices

- Plan CIDR ranges early to avoid overlap later.
- Leave room for growth, especially for GKE and private service connectivity.
- Separate production and non-production subnet address spaces.
- Enable VPC Flow Logs where observability and security matter.
- Use Private Google Access for workloads without public IPs.
- Keep subnet naming consistent and descriptive.
- Align subnet boundaries with security, ownership, and routing needs.

---

## Common mistakes to avoid

- Creating CIDR ranges that overlap across regions or environments.
- Making subnets too small for future scaling.
- Mixing unrelated workloads in the same subnet without a reason.
- Forgetting secondary IP planning for GKE.
- Relying on public IPs when private access patterns are more appropriate.

---

## When to create a new subnetwork

Create a new subnetwork when you need:

- a different region
- separate IP space
- stronger isolation
- different routing or NAT behavior
- different operational ownership
- dedicated GKE ranges

Do **not** create new subnets unnecessarily if the workload can safely share an existing subnet and the IP/routing model remains clear.

---

## Related Docs

- [GCP Subnet Terraform Module README](../gcp_subnet/README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Service List — Definitions](../../../gcp-service-list-definitions.md)
- [Google Cloud VPC Overview](https://cloud.google.com/vpc/docs/vpc)
- [Google Cloud Subnets Overview](https://cloud.google.com/vpc/docs/subnets)