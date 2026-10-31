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
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.40"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Unique suffix to avoid global naming collisions on storage accounts
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
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
# ZERO-NAT CUSTOM NETWORKING (VNet Injection - $0.00 Standby Cost)
# ----------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.139.0.0/16"]
  tags                = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.project_name}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

# DEV Subnets
resource "azurerm_subnet" "dev_public" {
  name                 = "${var.project_name}-dev-public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.139.1.0/24"]

  delegation {
    name = "databricks-delegation-dev-public"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet" "dev_private" {
  name                 = "${var.project_name}-dev-private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.139.2.0/24"]

  delegation {
    name = "databricks-delegation-dev-private"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "dev_public" {
  subnet_id                 = azurerm_subnet.dev_public.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "dev_private" {
  subnet_id                 = azurerm_subnet.dev_private.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# PROD Subnets
resource "azurerm_subnet" "prod_public" {
  name                 = "${var.project_name}-prod-public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.139.3.0/24"]

  delegation {
    name = "databricks-delegation-prod-public"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet" "prod_private" {
  name                 = "${var.project_name}-prod-private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.139.4.0/24"]

  delegation {
    name = "databricks-delegation-prod-private"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "prod_public" {
  subnet_id                 = azurerm_subnet.prod_public.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "prod_private" {
  subnet_id                 = azurerm_subnet.prod_private.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ----------------------------------------------------------------------
# DEV Azure Databricks Workspace (VNet Injected - No NAT Gateway)
# ----------------------------------------------------------------------
resource "azurerm_databricks_workspace" "dev" {
  name                        = "${var.project_name}-dev-ws"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku                         = var.sku
  managed_resource_group_name = "${var.project_name}-dev-managed-rg"

  # VNet Injection: Forces Databricks into our custom VNet without auto-creating a NAT Gateway
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.vnet.id
    public_subnet_name                                   = azurerm_subnet.dev_public.name
    private_subnet_name                                  = azurerm_subnet.dev_private.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.dev_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.dev_private.id
  }

  tags = merge(var.tags, {
    Environment = "Development"
  })
}

# DEV Isolated ADLS Gen2 Storage
resource "azurerm_storage_account" "dev_storage" {
  name                     = substr("${local.clean_name}dev${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  tags = merge(var.tags, {
    Environment = "Development"
  })
}

resource "azurerm_storage_data_lake_gen2_filesystem" "dev_container" {
  name               = "data"
  storage_account_id = azurerm_storage_account.dev_storage.id
}

# ----------------------------------------------------------------------
# PROD Azure Databricks Workspace (VNet Injected - No NAT Gateway)
# ----------------------------------------------------------------------
resource "azurerm_databricks_workspace" "prod" {
  name                        = "${var.project_name}-prod-ws"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku                         = var.sku
  managed_resource_group_name = "${var.project_name}-prod-managed-rg"

  # VNet Injection: Forces Databricks into our custom VNet without auto-creating a NAT Gateway
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.vnet.id
    public_subnet_name                                   = azurerm_subnet.prod_public.name
    private_subnet_name                                  = azurerm_subnet.prod_private.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.prod_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.prod_private.id
  }

  tags = merge(var.tags, {
    Environment = "Production"
  })
}

# PROD Isolated ADLS Gen2 Storage
resource "azurerm_storage_account" "prod_storage" {
  name                     = substr("${local.clean_name}prod${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  tags = merge(var.tags, {
    Environment = "Production"
  })
}

resource "azurerm_storage_data_lake_gen2_filesystem" "prod_container" {
  name               = "data"
  storage_account_id = azurerm_storage_account.prod_storage.id
}

# ----------------------------------------------------------------------
# UNITY CATALOG ACCESS CONNECTOR (System-Assigned Managed Identity)
# ----------------------------------------------------------------------
resource "azurerm_databricks_access_connector" "uc" {
  name                = "${var.project_name}-uc-connector"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant Access Connector permissions to ADLS Gen2 storage accounts (can be assigned manually or via Owner)
# resource "azurerm_role_assignment" "uc_dev_storage" {
#   scope                = azurerm_storage_account.dev_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_databricks_access_connector.uc.identity[0].principal_id
# }
# 
# resource "azurerm_role_assignment" "uc_prod_storage" {
#   scope                = azurerm_storage_account.prod_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_databricks_access_connector.uc.identity[0].principal_id
# }
