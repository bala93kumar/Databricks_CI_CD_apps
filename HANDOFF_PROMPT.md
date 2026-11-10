# Databricks Platform & Governance CI/CD: Context & Handoff Brief

This document is a comprehensive handoff guide for an AI assistant (such as Claude) to continue work on the **Azure Databricks Platform & Governance** repository with zero lost context.

---

## 1. Project Mission & Architecture

We are building an **Enterprise-grade, Zero-Standby-Cost (FinOps-optimized) Databricks Platform on Microsoft Azure** managed 100% as code via Terraform and GitHub Actions.

### Repository Separation (Two-Repo Enterprise Model)
- **Repo 1 (`Databricks_CI_CD_apps`) — Current Workspace**: 
  - **100% Admin & Governance Platform Repo**.
  - Manages: Azure Resource Groups, Zero-NAT Custom VNet networking, ADLS Gen2 storage accounts, Databricks DEV and PROD workspaces, Unity Catalog Medallion schemas, developer onboarding with FinOps guardrails, and automated developer compute provisioning.
  - **No application code** (cleaned up and isolated).
- **Repo 2 (Separate Developer Repo — Next Milestone)**:
  - Data Engineer pipeline code (PySpark jobs, unit tests, Databricks Asset Bundles / DABs `databricks.yml`, and CI/CD pipelines deploying to DEV and PROD).

### FinOps Constraints (Strict Cost Rules)
- **Idle Cost**: **₹0.00 / hour** (Zero paid Azure NAT Gateway, using Public IPs for secure egress).
- **Compute**: Single-node clusters (`Standard_D4ds_v4` in East US, 0 worker nodes, 4 cores total), with **10-minute auto-termination** (`autotermination_minutes = 10`).
- **Guardrail**: Developers are strictly forbidden from creating their own clusters (`allow_cluster_create = false`). Compute is admin-managed as code. Total actual test spend across days has been ~₹17 total.

---

## 2. Live Azure & Databricks Infrastructure

- **Azure Region**: `eastus` (Azure Pay-As-You-Go subscription)
- **Resource Group**: `dbx-demo-cicd-rg`
- **Remote Terraform Backend**:
  - Storage Account: `dbxdemodev80en`
  - Container: `tfstate`
  - Key: `terraform.tfstate`
- **Databricks Workspaces**:
  - **DEV**: `adb-7405605201845024.4.azuredatabricks.net`
  - **PROD**: `adb-7405618385351801.1.azuredatabricks.net`
- **Developer Account**:
  - Email: `bala93kumar@gmail.com` (invited to Azure Entra ID, workspace access enabled).

---

## 3. Pillar 1: Clean & Simple Medallion Governance

To keep the architecture clean, fast, and 100% reliable with zero metastore cross-visibility issues:
- **Catalogs Used**:
  - DEV: Workspace default catalog `dbx_demo_dev_ws_7405605201845024`
  - PROD: Workspace default catalog `dbx_demo_prod_ws_7405618385351801`
- **Schemas Managed via Terraform**:
  - `retail_bronze`: Raw ingested retail data
  - `retail_silver`: Cleaned and conformed tables
  - `retail_gold`: Aggregated analytics KPIs
- **RBAC**:
  - DEV: Data engineers have FULL WRITE (`USE_SCHEMA`, `SELECT`, `MODIFY`, `CREATE_TABLE`).
  - PROD: Data engineers have READ-ONLY (`USE_SCHEMA`, `SELECT`).
  - `account users` have `USE_SCHEMA`, `SELECT` so admins and teammates can query and view all schemas.

### Looped Developer Onboarding & Dedicated Compute
In `terraform/governance.tf`:
```hcl
locals {
  data_engineers = [
    {
      email        = "bala93kumar@gmail.com"
      display_name = "Bala Developer"
    }
  ]
}
```
- **Compute**: Each developer automatically receives a dedicated single-node cluster (`dev-cluster-bala93kumar`) with `SINGLE_USER` data security mode and `CAN_RESTART` permissions.
- **Offboarding**: Configured `force_delete_home_dir = true`. Commenting out a developer destroys the user, their compute, all Unity Catalog grants, and purges `/Users/<email>` automatically.

---

## 4. Immediate Action & Next Steps

1. **Current Branch**: `dev`.
2. **Pushing clean governance**:
   - Destroys all custom `dev_*` and `prod_*` catalogs.
   - Creates `retail_bronze`, `retail_silver`, `retail_gold` inside `dbx_demo_dev_ws_...`.
   - Creates `retail_bronze`, `retail_silver`, `retail_gold` inside `dbx_demo_prod_ws_...` with Read-Only RBAC.
3. **Verify Dev Workspace**:
   - Inspect Databricks DEV UI: Clean workspace with `retail_bronze`, `retail_silver`, `retail_gold`.
4. **Next Milestone — Developer Repo (Pillar 3)**:
   - Create a second repository (e.g. `retail-pyspark-pipeline`) containing PySpark pipelines, unit tests, and DABs (`databricks.yml`) to deploy ETL jobs using service principals.
