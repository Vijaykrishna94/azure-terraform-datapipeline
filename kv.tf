data "azurerm_client_config" "current" {}
# COnfiguring Key Vault
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
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey",
      "Verify", "Sign", "Purge", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]

    storage_permissions = [
      "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
    ]
  }
}


#######################################################################################          Access Policies                 ###########################################################################

resource "azurerm_key_vault_access_policy" "rcm-adf-principal" {
  key_vault_id = azurerm_key_vault.rcm_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.azure_adf_sp.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
  ]
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
  depends_on = [azuread_service_principal.azure_adf_sp]
}


resource "azurerm_key_vault_access_policy" "rcm-adf-mi" {
  key_vault_id = azurerm_key_vault.rcm_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.rcm_adf.identity[0].principal_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
  ]
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
  depends_on = [azuread_service_principal.azure_adls_sp]
}



resource "azurerm_key_vault_access_policy" "rcm-adls-principal" {
  key_vault_id = azurerm_key_vault.rcm_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.azure_adls_sp.object_id

  key_permissions = [
    "Get", "List", "UnwrapKey", "WrapKey"
  ]
  secret_permissions = [
    "Get", "List"
  ]
  depends_on = [azuread_service_principal.azure_adls_sp]
}



#######################################################################################          Secrets Creation             ###########################################################################


resource "azurerm_key_vault_secret" "rcm_sqldb_kv" {
  name         = "vj-sqldb-access-key-dev"
  value        = local.admin_password
  key_vault_id = azurerm_key_vault.rcm_kv.id
  depends_on   = [azurerm_mssql_database.rcm_db]
}


data "azurerm_storage_account" "rcm_adls_key" {
  name                = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}storage"
  resource_group_name = azurerm_resource_group.rcm_rg.name
  depends_on          = [azurerm_storage_account.rcm_adls]
}


resource "azurerm_key_vault_secret" "rcm_adls_kv" {
  name         = "vj-adls-access-key-dev"
  value        = data.azurerm_storage_account.rcm_adls_key.primary_access_key
  key_vault_id = azurerm_key_vault.rcm_kv.id
  depends_on   = [azurerm_storage_account.rcm_adls]
}



resource "azurerm_key_vault_secret" "rcm_adb_kv" {
  name         = "vj-adb-access-key-dev"
  value        = databricks_token.pat.token_value
  key_vault_id = azurerm_key_vault.rcm_kv.id
  depends_on   = [databricks_token.pat]
}


#######################################################################################          Scope Creation             ###########################################################################

#For Adb
resource "databricks_secret_scope" "kv" {
  name = "vj-rcm-kv"
  keyvault_metadata {
    resource_id = azurerm_key_vault.rcm_kv.id
    dns_name    = azurerm_key_vault.rcm_kv.vault_uri
  }
}