# resource "azurerm_data_factory_pipeline" "rcm_audit_pipline" {
#   name            = "example"
#   data_factory_id = azurerm_data_factory.example.id
# }





# azure keyvault linked service
resource "azurerm_data_factory_linked_service_key_vault" "rcm_kv_ls" {
  name            = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv-ls"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  key_vault_id    = azurerm_key_vault.rcm_kv.id
}


resource "azurerm_data_factory_linked_service_sql_server" "rcm_sqldb_ls" {
  name            = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-sqldb-ls"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  user_name = var.admin_username
  connection_string = "Integrated Security=False;Data Source=test;Initial Catalog=vijay;User ID=test;"
  key_vault_password {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.rcm_kv_ls.name
    secret_name         = "vj-sqldb-access-key-dev"
  }
}





# Get the kv id  
data "azurerm_key_vault" "current_key" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv"
  resource_group_name = azurerm_resource_group.rcm_rg.name
}

#Get the secret of adls
data "azurerm_key_vault_secret" "current_adls_secret" {
  name         = "vj-adls-access-key-dev"
  key_vault_id = data.azurerm_key_vault.current_key.id
}


resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "rcm_adls_ls" {
  name                  = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adls-ls"
  data_factory_id       = azurerm_data_factory.rcm_adf.id
  storage_account_key = data.azurerm_key_vault_secret.current_adls_secret.value
  url = "https://${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}storage.dfs.core.windows.net/"
}







