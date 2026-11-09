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
# 1. LIST-BASED CONFIGURATION (Declarative Catalog, Schemas & Users)
# ======================================================================

locals {
  # Add or remove developers here:
  data_engineers = [
    {
      email        = "bala93kumar@gmail.com"
      display_name = "Bala Developer"
    }
  ]

  # Add or remove schemas here:
  schemas = {
    "retail_silver" = {
      comment = "Cleaned tables managed via Terraform"
    }
    "retail_gold" = {
      comment = "Aggregated analytics managed via Terraform"
    }
  }
}

# ======================================================================
# 2. USER ONBOARDING AS CODE (Looped via for_each)
# ======================================================================

# Onboard developers into DEV workspace
resource "databricks_user" "dev_developer" {
  for_each              = { for u in local.data_engineers : u.email => u }
  provider              = databricks.dev
  user_name             = each.value.email
  display_name          = each.value.display_name
  allow_cluster_create  = false # FinOps guardrail: Strictly blocked from creating custom VMs!
  workspace_access      = true
  force_delete_home_dir = true  # Cleans up /Users/<email> folder upon offboarding
}

# Onboard developers into PROD workspace
resource "databricks_user" "prod_developer" {
  for_each              = { for u in local.data_engineers : u.email => u }
  provider              = databricks.prod
  user_name             = each.value.email
  display_name          = each.value.display_name
  allow_cluster_create  = false # In Prod: Cannot create any clusters!
  workspace_access      = true
  force_delete_home_dir = true
}

# ======================================================================
# 3. RBAC TEAMS / GROUPS AS CODE
# ======================================================================

# Group in DEV
resource "databricks_group" "dev_data_engineers" {
  provider     = databricks.dev
  display_name = "data_engineers"
}

resource "databricks_group_member" "dev_membership" {
  for_each  = databricks_user.dev_developer
  provider  = databricks.dev
  group_id  = databricks_group.dev_data_engineers.id
  member_id = each.value.id
}

# Group in PROD
resource "databricks_group" "prod_data_engineers" {
  provider     = databricks.prod
  display_name = "data_engineers"
}

resource "databricks_group_member" "prod_membership" {
  for_each  = databricks_user.prod_developer
  provider  = databricks.prod
  group_id  = databricks_group.prod_data_engineers.id
  member_id = each.value.id
}

# ======================================================================
# 4. WAY 1: ADMIN-MANAGED DEV CLUSTERS (10-Min Auto-Termination, Single Node)
# ======================================================================

# In Unity Catalog, Single-Node clusters require SINGLE_USER mode.
# By looping over data_engineers, each developer gets their own dedicated single-node VM.
# When a developer is removed from data_engineers, their cluster is automatically destroyed!
resource "databricks_cluster" "dev_developer_cluster" {
  for_each                = { for u in local.data_engineers : u.email => u }
  provider                = databricks.dev
  cluster_name            = "dev-cluster-${split("@", each.value.email)[0]}"
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = "Standard_D4ds_v4"
  num_workers             = 0  # Single-Node Mode (Driver only, 4 cores total)
  autotermination_minutes = 10 # Strictly shuts down after 10 mins of inactivity!
  data_security_mode      = "SINGLE_USER"
  single_user_name        = each.value.email

  spark_conf = {
    "spark.master" : "local[*]",
    "spark.databricks.cluster.profile" : "singleNode"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
    "Environment"   = "Development"
    "ManagedBy"     = "Terraform"
    "Owner"         = each.value.email
  }
}

# Grant each developer permission to ATTACH and RESTART their cluster
resource "databricks_permissions" "dev_cluster_perms" {
  for_each   = databricks_cluster.dev_developer_cluster
  provider   = databricks.dev
  cluster_id = each.value.cluster_id

  access_control {
    user_name        = each.key
    permission_level = "CAN_RESTART"
  }
}

# ======================================================================
# 5. MEDALLION SCHEMAS IN UNITY CATALOG (Looped via for_each)
# ======================================================================

# DEV Catalog & Schemas
data "databricks_catalog" "dev_workspace_catalog" {
  provider = databricks.dev
  name     = "dbx_demo_dev_ws_7405605201845024"
}

resource "databricks_schema" "dev_schemas" {
  for_each     = local.schemas
  provider     = databricks.dev
  catalog_name = data.databricks_catalog.dev_workspace_catalog.name
  name         = each.key
  comment      = "DEV: ${each.value.comment}"
}

# PROD Catalog & Schemas
data "databricks_catalog" "prod_workspace_catalog" {
  provider = databricks.prod
  name     = "dbx_demo_prod_ws_7405618385351801"
}

resource "databricks_schema" "prod_schemas" {
  for_each     = local.schemas
  provider     = databricks.prod
  catalog_name = data.databricks_catalog.prod_workspace_catalog.name
  name         = each.key
  comment      = "PROD: ${each.value.comment}"
}

# ======================================================================
# 6. RBAC PRIVILEGES: DEV (WRITE) vs PROD (READ-ONLY)
# ======================================================================

locals {
  # Build combinations of developers x schemas for DEV write grants
  dev_developer_schema_pairs = flatten([
    for dev_email, dev in databricks_user.dev_developer : [
      for schema_name, s in databricks_schema.dev_schemas : {
        key       = "${dev_email}.${schema_name}"
        principal = dev.user_name
        schema    = "${data.databricks_catalog.dev_workspace_catalog.name}.${schema_name}"
      }
    ]
  ])

  # Build combinations of developers x schemas for PROD read grants
  prod_developer_schema_pairs = flatten([
    for dev_email, dev in databricks_user.prod_developer : [
      for schema_name, s in databricks_schema.prod_schemas : {
        key       = "${dev_email}.${schema_name}"
        principal = dev.user_name
        schema    = "${data.databricks_catalog.prod_workspace_catalog.name}.${schema_name}"
      }
    ]
  ])
}

# DEV PRIVILEGE: Data Developers get FULL WRITE ACCESS in DEV Schemas!
resource "databricks_grant" "dev_grants" {
  for_each   = { for p in local.dev_developer_schema_pairs : p.key => p }
  provider   = databricks.dev
  schema     = each.value.schema
  principal  = each.value.principal
  privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  depends_on = [databricks_user.dev_developer, databricks_schema.dev_schemas]
}

# PROD PRIVILEGE: Data Developers get STRICTLY READ-ONLY ACCESS in PROD Schemas!
resource "databricks_grant" "prod_grants" {
  for_each   = { for p in local.prod_developer_schema_pairs : p.key => p }
  provider   = databricks.prod
  schema     = each.value.schema
  principal  = each.value.principal
  privileges = ["USE_SCHEMA", "SELECT"] # Read-Only in Production!
  depends_on = [databricks_user.prod_developer, databricks_schema.prod_schemas]
}

# ======================================================================
# 7. STATE MIGRATIONS (Preserves existing resources without destroying them)
# ======================================================================

moved {
  from = databricks_user.dev_developer
  to   = databricks_user.dev_developer["bala93kumar@gmail.com"]
}

moved {
  from = databricks_user.prod_developer
  to   = databricks_user.prod_developer["bala93kumar@gmail.com"]
}

moved {
  from = databricks_group_member.dev_membership
  to   = databricks_group_member.dev_membership["bala93kumar@gmail.com"]
}

moved {
  from = databricks_group_member.prod_membership
  to   = databricks_group_member.prod_membership["bala93kumar@gmail.com"]
}

moved {
  from = databricks_schema.dev_retail_silver
  to   = databricks_schema.dev_schemas["retail_silver"]
}

moved {
  from = databricks_schema.dev_retail_gold
  to   = databricks_schema.dev_schemas["retail_gold"]
}

moved {
  from = databricks_schema.prod_retail_silver
  to   = databricks_schema.prod_schemas["retail_silver"]
}

moved {
  from = databricks_schema.prod_retail_gold
  to   = databricks_schema.prod_schemas["retail_gold"]
}

moved {
  from = databricks_grant.dev_silver_write
  to   = databricks_grant.dev_grants["bala93kumar@gmail.com.retail_silver"]
}

moved {
  from = databricks_grant.dev_gold_write
  to   = databricks_grant.dev_grants["bala93kumar@gmail.com.retail_gold"]
}

moved {
  from = databricks_grant.prod_silver_read
  to   = databricks_grant.prod_grants["bala93kumar@gmail.com.retail_silver"]
}

moved {
  from = databricks_grant.prod_gold_read
  to   = databricks_grant.prod_grants["bala93kumar@gmail.com.retail_gold"]
}

moved {
  from = databricks_cluster.dev_shared_cluster
  to   = databricks_cluster.dev_developer_cluster["bala93kumar@gmail.com"]
}

moved {
  from = databricks_permissions.dev_cluster_perms
  to   = databricks_permissions.dev_cluster_perms["bala93kumar@gmail.com"]
}
