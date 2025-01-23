# Setting up resource group
resource "azurerm_resource_group" "rcm_rg" {
  name     = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-rg"
  location = var.resource_group_location
}

# Setting up  Storage account
resource "azurerm_storage_account" "rcm_adls" {
  name                     = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}storage"
  resource_group_name      = azurerm_resource_group.rcm_rg.name
  location                 = azurerm_resource_group.rcm_rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}



# Setting up containers
resource "azurerm_storage_container" "rcm_container" {
  for_each              = toset(["configs", "landing", "bronze", "silver", "gold", "tfstate"])
  name                  = each.key
  storage_account_name  = azurerm_storage_account.rcm_adls.name
  container_access_type = "private"
}



# Setting up adf account
resource "azurerm_data_factory" "rcm_adf" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adf"
  identity {
    type = "SystemAssigned"
  }
  location            = azurerm_resource_group.rcm_rg.location
  resource_group_name = azurerm_resource_group.rcm_rg.name
}

# setting up databricks account
resource "azurerm_databricks_workspace" "rcm_adb" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb"
  resource_group_name = azurerm_resource_group.rcm_rg.name
  location            = azurerm_resource_group.rcm_rg.location
  sku                 = "standard"
  tags = {
    Environment = "Staging"
  }
}



