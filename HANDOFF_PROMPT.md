# Databricks Platform & Governance CI/CD: Context & Handoff Brief

This document is a comprehensive handoff guide for an AI assistant (such as Claude) to continue work on the **Azure Databricks Platform & Governance** repository with zero lost context.

---

## 1. Project Mission & Architecture

We are building an **Enterprise-grade, Zero-Standby-Cost (FinOps-optimized) Databricks Platform on Microsoft Azure** managed 100% as code via Terraform and GitHub Actions.

### Repository Separation (Two-Repo Enterprise Model)
- **Repo 1 (`Databricks_CI_CD_apps`) — Current Workspace**: 
  - **100% Admin & Governance Platform Repo**.
  - Manages: Azure Resource Groups, Zero-NAT Custom VNet networking, ADLS Gen2 storage accounts, Databricks DEV and PROD workspaces, Unity Catalog Medallion catalogs and schemas, developer onboarding with FinOps guardrails, and automated developer compute provisioning.
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

## 3. What Was Just Implemented (`feature/loop-user-onboarding`)

### A. Medallion Catalogs & Schemas (Option A - Environment Prefixed)
Because DEV and PROD share a single Unity Catalog metastore in East US, catalog names are isolated with prefixes:
- **Storage Backing**:
  - Attached to Azure Access Connector (`dbx-demo-uc-connector`) with `Storage Blob Data Contributor` on ADLS Gen2.
  - DEV External Location: `abfss://data@dbxdemodev80en.dfs.core.windows.net/`
  - PROD External Location: `abfss://data@dbxdemoprod80en.dfs.core.windows.net/`
- **DEV Catalogs**:
  - `dev_bronze` (storage root: `.../bronze`)
  - `dev_silver` (storage root: `.../silver`)
  - `dev_gold` (storage root: `.../gold`)
- **PROD Catalogs**:
  - `prod_bronze` (storage root: `.../bronze`)
  - `prod_silver` (storage root: `.../silver`)
  - `prod_gold` (storage root: `.../gold`)
- **Business Domain Schemas (6 schemas generated via Cartesian matrix)**:
  - `<layer>.retail` (e.g., `dev_bronze.retail`, `dev_silver.retail`, `dev_gold.retail`)
  - `<layer>.marketing` (e.g., `dev_bronze.marketing`, `dev_silver.marketing`, `dev_gold.marketing`)

### B. Clean Purging of Deprecated Schemas
The old initial test schemas (`retail_silver` and `retail_gold` in the workspace default catalog) were mapped to `tomap({})` with `force_destroy = true`. When Terraform applies, it cleanly purges them from Databricks Unity Catalog.

### C. Looped Developer Onboarding & Dedicated Compute
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

### D. RBAC Privileges
- Developers receive `USE_CATALOG` on the Medallion catalogs.
- **DEV**: Full Write (`USE_SCHEMA`, `SELECT`, `MODIFY`, `CREATE_TABLE`) across all DEV domain schemas.
- **PROD**: Strictly Read-Only (`USE_SCHEMA`, `SELECT`).

### E. CI/CD Modernization (`.github/workflows/terraform.yml`)
- Removed fragile `-target=...` flags.
- Terraform runs standard `terraform plan` and `terraform apply -auto-approve`.
- All Azure networking resources in `terraform/main.tf` remain untouched (zero changes detected in remote state), and all `moved` state blocks process atomically.

---

## 4. Current State & Immediate Next Steps

1. **Current Branch**: `feature/loop-user-onboarding` (synced with remote `origin/feature/loop-user-onboarding`).
2. **Current GitHub Action Status**:
   - The last run encountered an intermittent GitHub runner scheduling outage:
     `Internal server error. Correlation ID: 1a35a32f-4575-4445-becc-b034877a964d`.
   - **Action**: Click **"Re-run all jobs"** on GitHub Actions or merge the open PR into `dev`.
3. **Verify Dev Workspace**:
   - After merge, inspect Databricks DEV UI:
     - Old `retail_silver` and `retail_gold` deleted.
     - New catalogs: `dev_bronze`, `dev_silver`, `dev_gold`.
     - Schemas: `retail`, `marketing` inside each catalog.
     - Cluster: `dev-cluster-bala93kumar` ready.
4. **Demonstrate Offboarding (FinOps & Governance Demo)**:
   - Comment out `bala93kumar@gmail.com` in `locals.data_engineers`.
   - Merge PR &rarr; watch Terraform delete user, cluster, grants, and home directory `/Users/bala93kumar@gmail.com`.
   - Uncomment to re-onboard.
5. **Promote to PROD**:
   - Open Pull Request: `dev` &rarr; `main`.
   - Merging to `main` applies the Medallion governance (`prod_bronze`, `prod_silver`, `prod_gold`) to the PROD workspace.
6. **Next Milestone — Developer Repo (Pillar 3)**:
   - Create a second repository (e.g. `retail-pyspark-pipeline`) containing PySpark pipelines, unit tests, and DABs (`databricks.yml`) to deploy ETL jobs using service principals.
