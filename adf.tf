# resource "azurerm_data_factory_pipeline" "rcm_audit_pipline" {
#   name            = "example"
#   data_factory_id = azurerm_data_factory.example.id
# }



# Get the kv id  
data "azurerm_key_vault" "current_adls_key" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv"
  resource_group_name = azurerm_resource_group.rcm_rg.name
}

#Get the secret of id
data "azurerm_key_vault_secret" "current_adls_secret" {
  name         = "vj-adls-access-key-dev"
  key_vault_id = data.azurerm_key_vault.current_adls_key.id
}


resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "rcm_adls_ls" {
  name                  = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adls-ls"
  data_factory_id       = azurerm_data_factory.rcm_adf.id
  storage_account_key = data.azurerm_key_vault_secret.current_adls_secret.value
  url = "https://${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}storage.dfs.core.windows.net/"
}


