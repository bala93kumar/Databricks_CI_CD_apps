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

  # Medallion Layers (Catalogs):
  medallion_layers = ["bronze", "silver", "gold"]

  # Business Domains (Schemas):
  domains = ["retail", "marketing"]

  # Medallion matrix: 3 layers x 2 domains = 6 schemas
  medallion_matrix = flatten([
    for layer in local.medallion_layers : [
      for dom in local.domains : {
        key     = "${layer}.${dom}"
        layer   = layer
        schema  = dom
        comment = "${upper(layer)} layer for ${dom} domain managed via Terraform"
      }
    ]
  ])
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
# 5. DEPRECATED OLD SCHEMAS (Empty map instructs Terraform to DESTROY them)
# ======================================================================

resource "databricks_schema" "dev_schemas" {
  for_each      = tomap({})
  provider      = databricks.dev
  catalog_name  = "dbx_demo_dev_ws_7405605201845024"
  name          = each.key
  force_destroy = true
}

resource "databricks_schema" "prod_schemas" {
  for_each      = tomap({})
  provider      = databricks.prod
  catalog_name  = "dbx_demo_prod_ws_7405618385351801"
  name          = each.key
  force_destroy = true
}

resource "databricks_grant" "dev_grants" {
  for_each   = tomap({})
  provider   = databricks.dev
  schema     = each.key
  principal  = "none"
  privileges = ["USE_SCHEMA"]
}

resource "databricks_grant" "prod_grants" {
  for_each   = tomap({})
  provider   = databricks.prod
  schema     = each.key
  principal  = "none"
  privileges = ["USE_SCHEMA"]
}

# ======================================================================
# 6. STORAGE CREDENTIALS & EXTERNAL LOCATIONS (Backs Medallion Storage)
# ======================================================================

# DEV Storage Credential (Managed Identity via Azure Access Connector)
resource "databricks_storage_credential" "dev_credential" {
  provider = databricks.dev
  name     = "${azurerm_databricks_access_connector.uc.name}-dev-cred"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.uc.id
  }
  comment = "Managed Identity credential for DEV Unity Catalog storage"
}

# DEV External Location (Root container for DEV data)
resource "databricks_external_location" "dev_external_location" {
  provider        = databricks.dev
  name            = "dev-data-external-location"
  url             = "abfss://${azurerm_storage_data_lake_gen2_filesystem.dev_container.name}@${azurerm_storage_account.dev_storage.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.dev_credential.id
  comment         = "External location for DEV Medallion catalogs"
  force_destroy   = true
}

# PROD Storage Credential
resource "databricks_storage_credential" "prod_credential" {
  provider = databricks.prod
  name     = "${azurerm_databricks_access_connector.uc.name}-prod-cred"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.uc.id
  }
  comment = "Managed Identity credential for PROD Unity Catalog storage"
}

# PROD External Location (Root container for PROD data)
resource "databricks_external_location" "prod_external_location" {
  provider        = databricks.prod
  name            = "prod-data-external-location"
  url             = "abfss://${azurerm_storage_data_lake_gen2_filesystem.prod_container.name}@${azurerm_storage_account.prod_storage.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.prod_credential.id
  comment         = "External location for PROD Medallion catalogs"
  force_destroy   = true
}

# ======================================================================
# 7. MEDALLION CATALOGS & SCHEMAS IN UNITY CATALOG (Option A: dev_*, prod_*)
# ======================================================================

# DEV Catalogs: dev_bronze, dev_silver, dev_gold
resource "databricks_catalog" "dev_medallion_catalogs" {
  for_each      = toset(local.medallion_layers)
  provider      = databricks.dev
  name          = "dev_${each.key}"
  storage_root  = "${databricks_external_location.dev_external_location.url}${each.key}"
  comment       = "DEV Medallion Catalog: ${upper(each.key)}"
  force_destroy = true
}

# DEV Schemas: retail & marketing inside dev_bronze, dev_silver, dev_gold
resource "databricks_schema" "dev_medallion_schemas" {
  for_each      = { for item in local.medallion_matrix : item.key => item }
  provider      = databricks.dev
  catalog_name  = databricks_catalog.dev_medallion_catalogs[each.value.layer].name
  name          = each.value.schema
  comment       = "DEV: ${each.value.comment}"
  force_destroy = true
}

# PROD Catalogs: prod_bronze, prod_silver, prod_gold
resource "databricks_catalog" "prod_medallion_catalogs" {
  for_each      = toset(local.medallion_layers)
  provider      = databricks.prod
  name          = "prod_${each.key}"
  storage_root  = "${databricks_external_location.prod_external_location.url}${each.key}"
  comment       = "PROD Medallion Catalog: ${upper(each.key)}"
  force_destroy = true
}

# PROD Schemas: retail & marketing inside prod_bronze, prod_silver, prod_gold
resource "databricks_schema" "prod_medallion_schemas" {
  for_each      = { for item in local.medallion_matrix : item.key => item }
  provider      = databricks.prod
  catalog_name  = databricks_catalog.prod_medallion_catalogs[each.value.layer].name
  name          = each.value.schema
  comment       = "PROD: ${each.value.comment}"
  force_destroy = true
}

# ======================================================================
# 8. RBAC PRIVILEGES: DEV (WRITE) vs PROD (READ-ONLY)
# ======================================================================

locals {
  # DEV: Developer x Catalog pairs (for USE_CATALOG)
  dev_developer_catalog_pairs = flatten([
    for dev_email, dev in databricks_user.dev_developer : [
      for layer, cat in databricks_catalog.dev_medallion_catalogs : {
        key       = "${dev_email}.${layer}"
        principal = dev.user_name
        catalog   = cat.name
      }
    ]
  ])

  # DEV: Developer x Schema pairs (for USE_SCHEMA, SELECT, MODIFY, CREATE_TABLE)
  dev_developer_schema_pairs = flatten([
    for dev_email, dev in databricks_user.dev_developer : [
      for key, s in databricks_schema.dev_medallion_schemas : {
        key       = "${dev_email}.${key}"
        principal = dev.user_name
        schema    = "${s.catalog_name}.${s.name}"
      }
    ]
  ])

  # PROD: Developer x Catalog pairs (for USE_CATALOG)
  prod_developer_catalog_pairs = flatten([
    for dev_email, dev in databricks_user.prod_developer : [
      for layer, cat in databricks_catalog.prod_medallion_catalogs : {
        key       = "${dev_email}.${layer}"
        principal = dev.user_name
        catalog   = cat.name
      }
    ]
  ])

  # PROD: Developer x Schema pairs (for USE_SCHEMA, SELECT - Read-only)
  prod_developer_schema_pairs = flatten([
    for dev_email, dev in databricks_user.prod_developer : [
      for key, s in databricks_schema.prod_medallion_schemas : {
        key       = "${dev_email}.${key}"
        principal = dev.user_name
        schema    = "${s.catalog_name}.${s.name}"
      }
    ]
  ])
}

# DEV: Allow all account users (Admins & Developers) to see DEV Catalogs
resource "databricks_grant" "dev_catalog_account_users" {
  for_each   = databricks_catalog.dev_medallion_catalogs
  provider   = databricks.dev
  catalog    = each.value.name
  principal  = "account users"
  privileges = ["USE_CATALOG"]
}

# DEV: Developers get USE_CATALOG on DEV Catalogs
resource "databricks_grant" "dev_catalog_grants" {
  for_each   = { for p in local.dev_developer_catalog_pairs : p.key => p }
  provider   = databricks.dev
  catalog    = each.value.catalog
  principal  = each.value.principal
  privileges = ["USE_CATALOG"]
  depends_on = [databricks_user.dev_developer, databricks_catalog.dev_medallion_catalogs]
}

# DEV: Allow all account users to read DEV Schemas
resource "databricks_grant" "dev_schema_account_users" {
  for_each   = databricks_schema.dev_medallion_schemas
  provider   = databricks.dev
  schema     = "${each.value.catalog_name}.${each.value.name}"
  principal  = "account users"
  privileges = ["USE_SCHEMA", "SELECT"]
}

# DEV: Developers get FULL WRITE ACCESS on DEV Schemas
resource "databricks_grant" "dev_schema_grants" {
  for_each   = { for p in local.dev_developer_schema_pairs : p.key => p }
  provider   = databricks.dev
  schema     = each.value.schema
  principal  = each.value.principal
  privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  depends_on = [databricks_user.dev_developer, databricks_schema.dev_medallion_schemas]
}

# PROD: Allow all account users to see PROD Catalogs
resource "databricks_grant" "prod_catalog_account_users" {
  for_each   = databricks_catalog.prod_medallion_catalogs
  provider   = databricks.prod
  catalog    = each.value.name
  principal  = "account users"
  privileges = ["USE_CATALOG"]
}

# PROD: Developers get USE_CATALOG on PROD Catalogs
resource "databricks_grant" "prod_catalog_grants" {
  for_each   = { for p in local.prod_developer_catalog_pairs : p.key => p }
  provider   = databricks.prod
  catalog    = each.value.catalog
  principal  = each.value.principal
  privileges = ["USE_CATALOG"]
  depends_on = [databricks_user.prod_developer, databricks_catalog.prod_medallion_catalogs]
}

# PROD: Allow all account users to read PROD Schemas
resource "databricks_grant" "prod_schema_account_users" {
  for_each   = databricks_schema.prod_medallion_schemas
  provider   = databricks.prod
  schema     = "${each.value.catalog_name}.${each.value.name}"
  principal  = "account users"
  privileges = ["USE_SCHEMA", "SELECT"]
}

# PROD: Developers get STRICTLY READ-ONLY ACCESS on PROD Schemas
resource "databricks_grant" "prod_schema_grants" {
  for_each   = { for p in local.prod_developer_schema_pairs : p.key => p }
  provider   = databricks.prod
  schema     = each.value.schema
  principal  = each.value.principal
  privileges = ["USE_SCHEMA", "SELECT"] # Read-Only in Production!
  depends_on = [databricks_user.prod_developer, databricks_schema.prod_medallion_schemas]
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
