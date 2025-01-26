# resource "azurerm_data_factory_pipeline" "rcm_audit_pipline" {
#   name            = "example"
#   data_factory_id = azurerm_data_factory.example.id
# }



#######################################################################################          Linked Services            ###########################################################################


# azure keyvault linked service
resource "azurerm_data_factory_linked_service_key_vault" "rcm_kv_ls" {
  name            = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv-ls"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  key_vault_id    = azurerm_key_vault.rcm_kv.id
}


# sql ls
resource "azurerm_data_factory_linked_service_sql_server" "rcm_sqldb_ls" {
  name              = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-sqldb-ls"
  data_factory_id   = azurerm_data_factory.rcm_adf.id
  user_name         = var.admin_username
  parameters        = { "db_name" : "string" }
  connection_string = "Integrated Security=False;Data Source = ${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}sql.database.windows.net ;Initial Catalog=@{linkedService().db_name};User ID=${var.admin_username}"
  depends_on        = [azurerm_key_vault_secret.rcm_sqldb_kv]
  key_vault_password {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.rcm_kv_ls.name
    secret_name         = "vj-sqldb-access-key-dev"
  }
}


resource "azurerm_data_factory_linked_service_azure_sql_database" "rcm_sql_ls" {
  name              = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-sql-ls"
  data_factory_id   = azurerm_data_factory.rcm_adf.id
  connection_string = "Integrated Security=False;Data Source = ${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}sql.database.windows.net ;Initial Catalog=@{linkedService().db_name};User ID=${var.admin_username};connection timeout=30"
  parameters        = { "db_name" : "string" }
  depends_on        = [azurerm_key_vault_secret.rcm_sqldb_kv]
  key_vault_password {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.rcm_kv_ls.name
    secret_name         = "vj-sqldb-access-key-dev"
  }
}




# Get the kv id  
data "azurerm_key_vault" "current_key" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv"
  resource_group_name = azurerm_resource_group.rcm_rg.name
  depends_on          = [azurerm_key_vault.rcm_kv]
}

#Get the secret of adls
data "azurerm_key_vault_secret" "current_adls_secret" {
  name         = "vj-adls-access-key-dev"
  key_vault_id = data.azurerm_key_vault.current_key.id
  depends_on   = [azurerm_key_vault_secret.rcm_adls_kv]
}


# adls ls
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "rcm_adls_ls" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adls-ls"
  data_factory_id     = azurerm_data_factory.rcm_adf.id
  storage_account_key = data.azurerm_key_vault_secret.current_adls_secret.value
  url                 = "https://${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}storage.dfs.core.windows.net/"
}





# databricks ls

data "databricks_cluster" "current_rcm_adb_cluster" {
  cluster_name = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}cluster"

}

resource "azurerm_data_factory_linked_service_azure_databricks" "rcm_adb_ls" {
  name                = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls"
  data_factory_id     = azurerm_data_factory.rcm_adf.id
  description         = "ADB Linked Service via Access Token"
  existing_cluster_id = data.databricks_cluster.current_rcm_adb_cluster.cluster_id
  key_vault_password {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.rcm_kv_ls.name
    secret_name         = "vj-adb-access-key-dev"
  }
  adb_domain = databricks_cluster.rcm_adb_cluster.url
  depends_on = [databricks_cluster.rcm_adb_cluster]
}




#######################################################################################           Datasets            ###########################################################################

#parquet
# resource "azurerm_data_factory_dataset_parquet" "rcm_parquet_ds" {
#   name                = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds"
#   data_factory_id     = azurerm_data_factory.rcm_adf.id
#   linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.rcm_adls_ls.name
#   depends_on = [ azurerm_data_factory_linked_service_data_lake_storage_gen2.rcm_adls_ls ]
#   parameters = { "container" : "string", "file_path" : "string","file_name" : "string" }
#   azure_blob_fs_location {
#     path =  "@dataset().file_path"
#     file_system =  "@dataset().container"
#     filename =  "@dataset().file_name"
#   }
#   compression_codec = "snappy"
# }


resource "azapi_resource" "rcm_sqldb_ds" {
  type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  parent_id = azurerm_data_factory.rcm_adf.id
  name      = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds"

  body = {
    api_version = "2018-06-01"
    properties = {
      annotations = [
      ]
      description = "string"
      folder = {
        name = "string"
      }
      linkedServiceName = {
        parameters = {
          db_name = "@dataset().db_name"
        }
        referenceName = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-sql-ls"
        type          = "LinkedServiceReference"
      }
      parameters = {
        db_name = {
          type = "string"
        }
      }
      parameters = {
        schema_name = {
          type = "string"
        }
      }
      parameters = {
        table_name = {
          type = "string"
        }
      }
      schema = []
      type   = "AzureSqlTable"
      // For remaining properties, see Dataset objects
      typeProperties = {
        schema = "@dataset().schema_name"
        table  = "@dataset().table_name"
      }
    }
  }
}


# resource "azurerm_data_factory_dataset_azure_sql_table" "rcm_sqltbl_ds" {
#   name              = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds"
#   data_factory_id   = azurerm_data_factory.rcm_adf.id
#   linked_service_id = azurerm_data_factory_linked_service_azure_sql_database.rcm_sql_ls.id
#   parameters =  { "db_name" : "", "schema_name" : "","table_name" : "" }
#   schema = "@dataset().schema_name"
#   table = "@dataset().table_name"
#   depends_on = [ azurerm_data_factory.rcm_adf, azurerm_data_factory_linked_service_azure_sql_database.rcm_sql_ls ]

#   connection {
#     host = azurerm_data_factory_linked_service_azure_sql_database.rcm_sql_ls.host
#     parameters ={
#           "db_name": {
#           "value": "@dataset().db_name",
#           "type": "Expression"
#                 }
#       }
#     # db_name = "@dataset().db_name"
#     # schema = "@dataset().schema_name"
#     # table = "@dataset().table_name"
#   }
# }

