# Create a resource group
resource "azurerm_resource_group" "rcm_rg" {
  name     = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-rg"
  location = "${var.resource_group_location}"
}

resource "azurerm_storage_account" "rcm_adls" {
  name                     = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}storage"
  resource_group_name      = azurerm_resource_group.rcm_rg.name
  location                 = azurerm_resource_group.rcm_rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_container" "rcm_container" {
    for_each = toset(["configs","landing","bronze","silver","gold"])
    name = each.key
    storage_account_name = azurerm_storage_account.rcm_adls.name
    container_access_type = "private"
}


