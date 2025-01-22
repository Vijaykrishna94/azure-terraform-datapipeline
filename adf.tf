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
  connection_string = "Integrated Security=False;Data Source=test;Initial Catalog=test;User ID=test;"
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







resource "azurerm_resource_group_template_deployment" "terraform-arm-sql-ls" {
  name                = "terraform-arm-sql-ls"
  resource_group_name = azurerm_resource_group.rcm_rg.name
  
  deployment_mode     = "Incremental"

  template_content = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "apiProfile": "2024-05-01-preview",
	"variables": {},
	"resources": [
 
 {

    "type": "/subscriptions/71458d97-9dd7-48da-8513-2222c61f78bf/resourceGroups/vj-rcm-dev-rg/providers/Microsoft.DataFactory/factories/vj-rcm-dev-adf/Microsoft.DataFactory/factories/linkedservices@2018-06-01",
    "name": "vj-rcm-dev-sql-ls",
    "properties": {
        "parameters": {
            "db_name": {
                "type": "string"
            }
        },
        "annotations": [],
        "type": "AzureSqlDatabase",
        "typeProperties": {
            "server": "vjrcmdevsql.database.windows.net",
            "database": "@{linkedService().db_name}",
            "encrypt": "mandatory",
            "trustServerCertificate": false,
            "authenticationType": "SQL",
            "userName": "azuresqladmin",
            "password": {
                "type": "AzureKeyVaultSecret",
                "store": {
                    "referenceName": "vj-rcm-dev-kv-ls",
                    "type": "LinkedServiceReference"
                },
                "secretName": "vj-sqldb-access-key-dev"
             }
           }
         }
       }
     ]
  }
    TEMPLATE
}