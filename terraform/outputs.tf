output "dev_workspace_url" {
  description = "Web URL for Dev Databricks workspace"
  value       = "https://${azurerm_databricks_workspace.dev.workspace_url}"
}

output "dev_workspace_id" {
  description = "Workspace ID for Dev"
  value       = azurerm_databricks_workspace.dev.workspace_id
}

output "dev_storage_account_name" {
  description = "Dev ADLS Gen2 Storage Account Name"
  value       = azurerm_storage_account.dev_storage.name
}

output "dev_storage_abfss_path" {
  description = "ABFSS path for Dev data container"
  value       = "abfss://${azurerm_storage_data_lake_gen2_filesystem.dev_container.name}@${azurerm_storage_account.dev_storage.name}.dfs.core.windows.net"
}

output "prod_workspace_url" {
  description = "Web URL for Prod Databricks workspace"
  value       = "https://${azurerm_databricks_workspace.prod.workspace_url}"
}

output "prod_workspace_id" {
  description = "Workspace ID for Prod"
  value       = azurerm_databricks_workspace.prod.workspace_id
}

output "prod_storage_account_name" {
  description = "Prod ADLS Gen2 Storage Account Name"
  value       = azurerm_storage_account.prod_storage.name
}

output "prod_storage_abfss_path" {
  description = "ABFSS path for Prod data container"
  value       = "abfss://${azurerm_storage_data_lake_gen2_filesystem.prod_container.name}@${azurerm_storage_account.prod_storage.name}.dfs.core.windows.net"
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.rg.name
}
