terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Unique suffix to prevent Azure Storage naming collisions (3-24 lowercase/digits only)
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  # Strip hyphens and keep within Azure 24-char limit for storage accounts
  clean_name = replace(lower(var.project_name), "-", "")
}

# ----------------------------------------------------------------------
# Resource Group
# ----------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# ----------------------------------------------------------------------
# DEV Azure Databricks Workspace & Isolated Storage
# ----------------------------------------------------------------------
resource "azurerm_databricks_workspace" "dev" {
  name                        = "${var.project_name}-dev-ws"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku                         = var.sku
  managed_resource_group_name = "${var.project_name}-dev-managed-rg"

  tags = merge(var.tags, {
    Environment = "Development"
  })
}

resource "azurerm_storage_account" "dev_storage" {
  name                     = substr("${local.clean_name}dev${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Enables ADLS Gen2 Hierarchical Namespace

  tags = merge(var.tags, {
    Environment = "Development"
  })
}

resource "azurerm_storage_data_lake_gen2_filesystem" "dev_container" {
  name               = "data"
  storage_account_id = azurerm_storage_account.dev_storage.id
}

# ----------------------------------------------------------------------
# PROD Azure Databricks Workspace & Isolated Storage
# ----------------------------------------------------------------------
resource "azurerm_databricks_workspace" "prod" {
  name                        = "${var.project_name}-prod-ws"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku                         = var.sku
  managed_resource_group_name = "${var.project_name}-prod-managed-rg"

  tags = merge(var.tags, {
    Environment = "Production"
  })
}

resource "azurerm_storage_account" "prod_storage" {
  name                     = substr("${local.clean_name}prod${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Enables ADLS Gen2 Hierarchical Namespace

  tags = merge(var.tags, {
    Environment = "Production"
  })
}

resource "azurerm_storage_data_lake_gen2_filesystem" "prod_container" {
  name               = "data"
  storage_account_id = azurerm_storage_account.prod_storage.id
}
