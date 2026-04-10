# Google Cloud Folder: 

## What is a Folder in Google Cloud?

A **Folder** is a logical container in the [Google Cloud Resource Manager hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy):

**Organization → Folder → Project → Resources**

Folders sit between an Organization and Projects. They let teams group projects by business unit, environment, compliance boundary, or ownership model.

---

## What does a Folder do?

A Folder helps with governance and scale in four main ways:

1. **Structure and ownership**
	- Organizes projects into meaningful groups (e.g., `finance`, `engineering`, `marketing`).

2. **Access control (IAM inheritance)**
	- IAM roles set at folder level are inherited by child projects/resources unless overridden.
	- Example: grant `roles/viewer` once at folder level instead of per project.

3. **Policy enforcement**
	- Apply [Organization Policy constraints](https://cloud.google.com/resource-manager/docs/organization-policy/overview) at folder level (e.g., restrict external IP usage, allowed regions).

4. **Audit and operations boundaries**
	- Configure folder-level logging sinks and contacts for targeted monitoring and notifications.

---

## Why use Folders instead of only Projects?

Without folders, every policy and permission must be repeated across many projects. As project count grows, this becomes hard to maintain and error-prone.

Folders provide a middle layer for **delegation**, **standardization**, and **least-privilege access**.

---

## Real-life examples

## 1) Enterprise by business unit

**Scenario:** A company has three departments.

- Folder: `finance`
- Folder: `engineering`
- Folder: `hr`

Projects for each department live under its folder. Finance admins can manage only finance projects while central security applies org-wide controls.

## 2) Environment separation (dev/stage/prod)

**Scenario:** A platform team wants strict separation.

- Folder: `dev`
- Folder: `stage`
- Folder: `prod`

`prod` folder has tighter IAM and stricter policies than `dev` (for example, stronger restrictions on service account key creation or public exposure).

## 3) Compliance boundary

**Scenario:** Regulated workloads require tighter controls.

- Folder: `regulated`
- Folder: `non-regulated`

The `regulated` folder can enforce policy constraints and enhanced monitoring for all contained projects.

## 4) Shared platform vs application teams

**Scenario:** Central platform team manages common services.

- Folder: `platform-shared`
  - Projects for networking, logging, security tooling
- Folder: `applications`
  - Projects for product teams

This model keeps foundational services centralized while app teams retain autonomy in their own projects.

---

## Best practices

- Keep folder names clear and aligned to ownership.
- Prefer applying IAM and policies at the highest sensible level.
- Use separate folders for production and non-production.
- Avoid overly deep folder trees unless there is a governance need.
- Document folder purpose and owner.

---

## Related Docs

- [GCP Folder Terraform Module README](README.md)
- [GCP Module & Service Hierarchy](../../../gcp-module-service-list.md)
- [Google Cloud Resource Hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
