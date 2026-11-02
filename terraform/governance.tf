# ======================================================================
# UNITY CATALOG RBAC, SHARED COMPUTE & DEVELOPER ONBOARDING (DEV & PROD)
# ======================================================================

# Databricks Providers for DEV and PROD Workspaces
provider "databricks" {
  alias = "dev"
  host  = azurerm_databricks_workspace.dev.workspace_url
}

provider "databricks" {
  alias = "prod"
  host  = azurerm_databricks_workspace.prod.workspace_url
}

# ======================================================================
# 1. USER ONBOARDING AS CODE (Zero UI Touching!)
# ======================================================================

# Developer onboarded into DEV workspace
resource "databricks_user" "dev_developer" {
  provider             = databricks.dev
  user_name            = "bala93kumar@gmail.com"
  display_name         = "Bala Developer"
  allow_cluster_create = false # FinOps guardrail: Strictly blocked from creating VMs!
}

# Developer onboarded into PROD workspace (with read-only rights)
resource "databricks_user" "prod_developer" {
  provider             = databricks.prod
  user_name            = "bala93kumar@gmail.com"
  display_name         = "Bala Developer"
  allow_cluster_create = false # In Prod: Cannot create any clusters!
}

# ======================================================================
# 2. RBAC TEAMS / GROUPS AS CODE
# ======================================================================

# Group in DEV
resource "databricks_group" "dev_data_engineers" {
  provider     = databricks.dev
  display_name = "data_engineers"
}

resource "databricks_group_member" "dev_membership" {
  provider  = databricks.dev
  group_id  = databricks_group.dev_data_engineers.id
  member_id = databricks_user.dev_developer.id
}

# Group in PROD
resource "databricks_group" "prod_data_engineers" {
  provider     = databricks.prod
  display_name = "data_engineers"
}

resource "databricks_group_member" "prod_membership" {
  provider  = databricks.prod
  group_id  = databricks_group.prod_data_engineers.id
  member_id = databricks_user.prod_developer.id
}

# ======================================================================
# 3. WAY 1: ADMIN-MANAGED DEV CLUSTER (10-Min Auto-Termination, Single Node)
# ======================================================================

resource "databricks_cluster" "dev_shared_cluster" {
  provider                = databricks.dev
  cluster_name            = "Shared-Dev-SingleNode-Cluster"
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = "Standard_D4ds_v4" # Exact node size with 10 cores available in East US!
  num_workers             = 0                  # Single-Node Mode (Driver only, 4 cores total)
  autotermination_minutes = 10                 # Strictly shuts down after 10 mins of inactivity!
  data_security_mode      = "SINGLE_USER"
  single_user_name        = databricks_user.dev_developer.user_name

  spark_conf = {
    "spark.master" : "local[*]",
    "spark.databricks.cluster.profile" : "singleNode"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
    "Environment"   = "Development"
    "ManagedBy"     = "Terraform"
  }
}

# Grant developer permission to ATTACH and RESTART this cluster
resource "databricks_permissions" "dev_cluster_perms" {
  provider   = databricks.dev
  cluster_id = databricks_cluster.dev_shared_cluster.cluster_id

  access_control {
    user_name        = databricks_user.dev_developer.user_name
    permission_level = "CAN_RESTART"
  }
}

# ======================================================================
# 4. MEDALLION SCHEMAS IN UNITY CATALOG
# ======================================================================

# DEV Schemas
data "databricks_catalog" "dev_workspace_catalog" {
  provider = databricks.dev
  name     = "dbx_demo_dev_ws_7405605201845024"
}

resource "databricks_schema" "dev_retail_silver" {
  provider     = databricks.dev
  catalog_name = data.databricks_catalog.dev_workspace_catalog.name
  name         = "retail_silver"
  comment      = "DEV: Cleaned tables managed via Terraform"
}

resource "databricks_schema" "dev_retail_gold" {
  provider     = databricks.dev
  catalog_name = data.databricks_catalog.dev_workspace_catalog.name
  name         = "retail_gold"
  comment      = "DEV: Aggregated analytics managed via Terraform"
}

# PROD Schemas
data "databricks_catalog" "prod_workspace_catalog" {
  provider = databricks.prod
  name     = "dbx_demo_prod_ws_7405618385351801"
}

resource "databricks_schema" "prod_retail_silver" {
  provider     = databricks.prod
  catalog_name = data.databricks_catalog.prod_workspace_catalog.name
  name         = "retail_silver"
  comment      = "PROD: Cleaned production tables managed via Terraform"
}

resource "databricks_schema" "prod_retail_gold" {
  provider     = databricks.prod
  catalog_name = data.databricks_catalog.prod_workspace_catalog.name
  name         = "retail_gold"
  comment      = "PROD: Production analytics managed via Terraform"
}

# ======================================================================
# 5. RBAC PRIVILEGES: DEV (WRITE) vs PROD (READ-ONLY)
# ======================================================================

# DEV PRIVILEGE: Data Developer gets FULL WRITE ACCESS in DEV Silver AND Gold!
resource "databricks_grant" "dev_silver_write" {
  provider   = databricks.dev
  schema     = "${data.databricks_catalog.dev_workspace_catalog.name}.${databricks_schema.dev_retail_silver.name}"
  principal  = databricks_user.dev_developer.user_name
  privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  depends_on = [databricks_user.dev_developer, databricks_schema.dev_retail_silver]
}

resource "databricks_grant" "dev_gold_write" {
  provider   = databricks.dev
  schema     = "${data.databricks_catalog.dev_workspace_catalog.name}.${databricks_schema.dev_retail_gold.name}"
  principal  = databricks_user.dev_developer.user_name
  privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  depends_on = [databricks_user.dev_developer, databricks_schema.dev_retail_gold]
}

# PROD PRIVILEGE: Data Developer gets STRICTLY READ-ONLY ACCESS in PROD Silver & Gold
resource "databricks_grant" "prod_silver_read" {
  provider   = databricks.prod
  schema     = "${data.databricks_catalog.prod_workspace_catalog.name}.${databricks_schema.prod_retail_silver.name}"
  principal  = databricks_user.prod_developer.user_name
  privileges = ["USE_SCHEMA", "SELECT"] # Read-Only in Production!
  depends_on = [databricks_user.prod_developer, databricks_schema.prod_retail_silver]
}

resource "databricks_grant" "prod_gold_read" {
  provider   = databricks.prod
  schema     = "${data.databricks_catalog.prod_workspace_catalog.name}.${databricks_schema.prod_retail_gold.name}"
  principal  = databricks_user.prod_developer.user_name
  privileges = ["USE_SCHEMA", "SELECT"] # Read-Only in Production!
  depends_on = [databricks_user.prod_developer, databricks_schema.prod_retail_gold]
}
