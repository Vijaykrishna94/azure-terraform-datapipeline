data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "rcm_kv" {
  name                        = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv"
  location                    = azurerm_resource_group.rcm_rg.location
  resource_group_name         = azurerm_resource_group.rcm_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}




# resource "azurerm_key_vault_access_policy" "rcm-adf-principal" {
#   key_vault_id = azurerm_key_vault.rcm_kv.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = azuread_service_principal.azuread_sp.object_id

#   key_permissions = [
#     "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
#   ]
#   secret_permissions = [
#     "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
#   ]

# }