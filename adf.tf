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


# delta lake
resource "azapi_resource" "rcm_dl_ls" {
  type      = "Microsoft.DataFactory/factories/linkedservices@2018-06-01"
  parent_id = azurerm_data_factory.rcm_adf.id
  name      = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-dl-ls"
  body = {
    properties = {
      annotations = []
      description = "string"
      // For remaining properties, see LinkedService objects
      type = "AzureDatabricksDeltaLake"
      typeProperties = {
        domain    = "https://${azurerm_databricks_workspace.rcm_adb.workspace_url}"
        clusterId = data.databricks_cluster.current_rcm_adb_cluster.cluster_id
        accessToken = {
          type = "AzureKeyVaultSecret"
          // For remaining properties, see SecretBase objects
          secretName = "vj-adb-access-key-dev"
          store = {
            referenceName = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-kv-ls"
            type          = "LinkedServiceReference"
          }
        }
      }
    }
  }
}

#######################################################################################           Datasets            ###########################################################################

#parquet
resource "azurerm_data_factory_dataset_parquet" "rcm_parquet_ds" {
  name                = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds"
  data_factory_id     = azurerm_data_factory.rcm_adf.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.rcm_adls_ls.name
  depends_on          = [azurerm_data_factory_linked_service_data_lake_storage_gen2.rcm_adls_ls]
  parameters          = { "container" : "string", "file_path" : "string", "file_name" : "string" }
  azure_blob_fs_location {
    path        = "@dataset().file_path"
    file_system = "@dataset().container"
    filename    = "@dataset().file_name"
  }
  compression_codec = "snappy"
}

# Sql Table
resource "azapi_resource" "rcm_sqldb_ds" {
  type                      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  parent_id                 = azurerm_data_factory.rcm_adf.id
  name                      = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds"
  schema_validation_enabled = false

  body = {
    apiVersion = "2018-06-01"
    properties = {
      annotations = [
      ]
      description = "string"
      linkedServiceName = {
        parameters = {
          db_name = {
            value = "@dataset().db_name"
            type  = "Expression"
          }
        }
        referenceName = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-sql-ls"
        type          = "LinkedServiceReference"
      }
      parameters = {
        db_name = {
          type = "string"
        }
        schema_name = {
          type = "string"
        }
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

# delimeted file

resource "azapi_resource" "rcm_flatfile_ds" {
  type                      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  parent_id                 = azurerm_data_factory.rcm_adf.id
  name                      = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_flatfile_ds"
  schema_validation_enabled = false
  body = {
    properties = {
      annotations = []
      description = "string"
      linkedServiceName = {
        referenceName = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adls-ls"
        type          = "LinkedServiceReference"
      }
      parameters = {
        container = {
          type = "string"
        }
        folder = {
          type = "string"
        }
        file_name = {
          type = "string"
        }
      }

      schema = [{
        name = "database"
        type = "String"
        },
        {
          name = "datasource"
          type = "String"
        },
        {
          name = "tablename"
          type = "String"
        },
        {
          name = "loadtype"
          type = "String"
        },
        {
          name = "watermark"
          type = "String"
        },
        {
          name = "is_active"
          type = "String"
        },
        {
          name = "targetpath"
          type = "String"
        }
      ]
      type = "DelimitedText"
      typeProperties = {
        columnDelimiter  = ","
        escapeChar       = "\\"
        firstRowAsHeader = true
        location = {
          fileName = {
            value = "@dataset().file_name"
            type  = "Expression"
          }
          folderPath = {
            value = "@dataset().folder"
            type  = "Expression"
          }
          container = {
            value = "@dataset().container"
            type  = "Expression"
          }
          type = "AzureBlobFSLocation"
          // For remaining properties, see DatasetLocation objects

        }
        quoteChar = "\""
      }
    }
  }
}


# Delta Table 
resource "azapi_resource" "rcm_dl_ds" {
  type                      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  parent_id                 = azurerm_data_factory.rcm_adf.id
  name                      = "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds"
  schema_validation_enabled = false
  body = { properties = {
    annotations = []
    linkedServiceName = {
      referenceName = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-dl-ls"
      type          = "LinkedServiceReference"
    }
    parameters = {
      schema_name = {
        type = "string"
      }
      table_name = {
        type = "string"
      }
    }
    schema = []
    type   = "AzureDatabricksDeltaLakeDataset"
    // For remaining properties, see Dataset objects
    typeProperties = {
      database = {
        value = "@dataset().schema_name"
        type  = "Expression"
      }
      table = {
        value = "@dataset().table_name"
        type  = "Expression"
      }
    }
    }
  }
}

#######################################################################################           Pipeline            ###########################################################################


resource "azurerm_data_factory_pipeline" "vj_rcm_active_tables_pl" {
  name            = "pl_active_tables"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  variables = {
    "items" = "" 
  }
  activities_json = <<JSON
[
  {
                "name": "config_emr_lkp",
                "type": "Lookup",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "DelimitedTextSource",
                        "storeSettings": {
                            "type": "AzureBlobFSReadSettings",
                            "recursive": true,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "DelimitedTextReadSettings"
                        }
                    },
                    "dataset": {
                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_flatfile_ds",
                        "type": "DatasetReference",
                        "parameters": {
                            "container": "configs",
                            "folder": "emr",
                            "file_name": "load_config.csv"
                        }
                    },
                    "firstRowOnly": false
                }
            },
            {
                "name": "Iter_Tables",
                "description": "",
                "type": "ForEach",
                "dependsOn": [
                    {
                        "activity": "config_emr_lkp",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "items": {
                        "value": "@activity('config_emr_lkp').output.value",
                        "type": "Expression"
                    },
                    "isSequential": true,
                    "activities": [
                        {
                            "name": "IF_Active",
                            "type": "IfCondition",
                            "dependsOn": [],
                            "userProperties": [],
                            "typeProperties": {
                                "expression": {
                                    "value": "@equals(item().is_active,'1')",
                                    "type": "Expression"
                                },
                                "ifTrueActivities": [
                                    {
                                        "name": "Append_Tables",
                                        "type": "AppendVariable",
                                        "dependsOn": [],
                                        "userProperties": [],
                                        "typeProperties": {
                                            "variableName": "items",
                                            "value": {
                                                "value": "@item()",
                                                "type": "Expression"
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                }
            },
            {
                "name": "Collect_tables",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Iter_Tables",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "pipelineReturnValue",
                    "value": [
                        {
                            "key": "item",
                            "value": {
                                "type": "Expression",
                                "content": "@variables('items')"
                            }
                        }
                    ],
                    "setSystemVariable": true
                }
            }
]
  JSON
}


resource "azurerm_data_factory_pipeline" "vj_rcm_src_adls_pl" {
  name            = "pl_emr_src_to_adls"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  variables = {
    "items" = "" 
    "item" = ""
    "Is_Archived" = ""
  }
  activities_json = <<JSON
[
{
                "name": "Iter_logs",
                "type": "ForEach",
                "dependsOn": [
                    {
                        "activity": "Execute_Active_Tables",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "items": {
                        "value": "@activity('Execute_Active_Tables').output.pipelineReturnValue.item",
                        "type": "Expression"
                    },
                    "isSequential": false,
                    "batchCount": 5,
                    "activities": [
                        {
                            "name": "File_exist",
                            "type": "GetMetadata",
                            "dependsOn": [],
                            "policy": {
                                "timeout": "0.12:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "dataset": {
                                    "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "container": "bronze",
                                        "file_path": "@item().targetpath",
                                        "file_name": "@split(item().tablename,'.')[1]"
                                    }
                                },
                                "fieldList": [
                                    "exists"
                                ],
                                "storeSettings": {
                                    "type": "AzureBlobFSReadSettings",
                                    "recursive": true,
                                    "enablePartitionDiscovery": false
                                },
                                "formatSettings": {
                                    "type": "ParquetReadSettings"
                                }
                            }
                        },
                        {
                            "name": "IF_File_Exists",
                            "type": "IfCondition",
                            "dependsOn": [
                                {
                                    "activity": "File_exist",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "expression": {
                                    "value": "@equals(activity('File_exist').output.exists,true )",
                                    "type": "Expression"
                                },
                                "ifFalseActivities": [
                                    {
                                        "name": "Create_Dataset",
                                        "type": "Copy",
                                        "dependsOn": [],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 2,
                                            "retryIntervalInSeconds": 45,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureSqlSource",
                                                "queryTimeout": "02:00:00",
                                                "partitionOption": "None"
                                            },
                                            "sink": {
                                                "type": "ParquetSink",
                                                "storeSettings": {
                                                    "type": "AzureBlobFSWriteSettings",
                                                    "copyBehavior": "PreserveHierarchy"
                                                },
                                                "formatSettings": {
                                                    "type": "ParquetWriteSettings"
                                                }
                                            },
                                            "enableStaging": false,
                                            "translator": {
                                                "type": "TabularTranslator",
                                                "typeConversion": true,
                                                "typeConversionSettings": {
                                                    "allowDataTruncation": true,
                                                    "treatBooleanAsNumber": false
                                                }
                                            }
                                        },
                                        "inputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "db_name": {
                                                        "value": "@item().database",
                                                        "type": "Expression"
                                                    },
                                                    "schema_name": {
                                                        "value": "@split(item().tablename,'.')[0]",
                                                        "type": "Expression"
                                                    },
                                                    "table_name": "@split(item().tablename,'.')[1]"
                                                }
                                            }
                                        ],
                                        "outputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "container": "bronze",
                                                    "file_path": "@item().targetpath",
                                                    "file_name": "@split(item().tablename,'.')[1]"
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "name": "Update_Audit_log_Create",
                                        "type": "Lookup",
                                        "dependsOn": [
                                            {
                                                "activity": "Create_Dataset",
                                                "dependencyConditions": [
                                                    "Succeeded"
                                                ]
                                            }
                                        ],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureDatabricksDeltaLakeSource",
                                                "query": {
                                                    "value": "@concat('INSERT INTO  audit.load_logs(data_source ,tablename ,numberofrowscopied ,watermarkcolumnname ,loaddate) VALUES(''', item().datasource,''',''',item().tablename,''',''',activity('Create_Dataset').output.rowscopied,''',''',item().watermark,''',''',utcNOW(),''')')\n",
                                                    "type": "Expression"
                                                }
                                            },
                                            "dataset": {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "schema_name": "'a'",
                                                    "table_name": "'b'"
                                                }
                                            },
                                            "firstRowOnly": false
                                        }
                                    }
                                ],
                                "ifTrueActivities": [
                                    {
                                        "name": "Archive_Data",
                                        "type": "Copy",
                                        "dependsOn": [],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "ParquetSource",
                                                "storeSettings": {
                                                    "type": "AzureBlobFSReadSettings",
                                                    "recursive": true,
                                                    "enablePartitionDiscovery": false
                                                },
                                                "formatSettings": {
                                                    "type": "ParquetReadSettings"
                                                }
                                            },
                                            "sink": {
                                                "type": "ParquetSink",
                                                "storeSettings": {
                                                    "type": "AzureBlobFSWriteSettings"
                                                },
                                                "formatSettings": {
                                                    "type": "ParquetWriteSettings"
                                                }
                                            },
                                            "enableStaging": false,
                                            "translator": {
                                                "type": "TabularTranslator",
                                                "typeConversion": true,
                                                "typeConversionSettings": {
                                                    "allowDataTruncation": true,
                                                    "treatBooleanAsNumber": false
                                                }
                                            }
                                        },
                                        "inputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "container": "bronze",
                                                    "file_path": {
                                                        "value": "@item().targetpath",
                                                        "type": "Expression"
                                                    },
                                                    "file_name": {
                                                        "value": "@split(item().tablename,'.')[1]",
                                                        "type": "Expression"
                                                    }
                                                }
                                            }
                                        ],
                                        "outputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "container": "bronze",
                                                    "file_path": {
                                                        "value": "@concat(item().targetpath,'/Archive/',\n    formatDateTime(utcNOW(),'yyyy'),'/',\n    formatDateTime(utcNOW(),'%M'),'/',\n    formatDateTime(utcNOW(),'%d') )",
                                                        "type": "Expression"
                                                    },
                                                    "file_name": {
                                                        "value": "@split(item().tablename,'.')[1]",
                                                        "type": "Expression"
                                                    }
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "name": "Set_is_archived",
                                        "type": "SetVariable",
                                        "dependsOn": [
                                            {
                                                "activity": "Archive_Data",
                                                "dependencyConditions": [
                                                    "Succeeded"
                                                ]
                                            }
                                        ],
                                        "policy": {
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "variableName": "Is_Archived",
                                            "value": {
                                                "value": "@concat('True','_',item().loadtype)",
                                                "type": "Expression"
                                            }
                                        }
                                    }
                                ]
                            }
                        },
                        {
                            "name": "IF_Full_Load",
                            "type": "IfCondition",
                            "state": "Inactive",
                            "onInactiveMarkAs": "Succeeded",
                            "dependsOn": [],
                            "userProperties": [],
                            "typeProperties": {
                                "expression": {
                                    "value": "@equals(item().loadtype,'Full')",
                                    "type": "Expression"
                                },
                                "ifFalseActivities": [
                                    {
                                        "name": "COPY_Incrmental_Load_1",
                                        "type": "Copy",
                                        "dependsOn": [
                                            {
                                                "activity": "Get_Latest_Date_1",
                                                "dependencyConditions": [
                                                    "Succeeded"
                                                ]
                                            }
                                        ],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureSqlSource",
                                                "sqlReaderQuery": {
                                                    "value": "@concat('SELECT * ,   ''',item().datasource,''' AS datasource from ',item().tablename,' where ',item().watermark,'>= ''',activity('Get_Latest_Date').output.firstRow.last_fetched_date,'''')",
                                                    "type": "Expression"
                                                },
                                                "queryTimeout": "02:00:00",
                                                "partitionOption": "None"
                                            },
                                            "sink": {
                                                "type": "ParquetSink",
                                                "storeSettings": {
                                                    "type": "AzureBlobFSWriteSettings"
                                                },
                                                "formatSettings": {
                                                    "type": "ParquetWriteSettings"
                                                }
                                            },
                                            "enableStaging": false,
                                            "translator": {
                                                "type": "TabularTranslator",
                                                "typeConversion": true,
                                                "typeConversionSettings": {
                                                    "allowDataTruncation": true,
                                                    "treatBooleanAsNumber": false
                                                }
                                            }
                                        },
                                        "inputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "db_name": {
                                                        "value": "@item().database",
                                                        "type": "Expression"
                                                    },
                                                    "schema_name": {
                                                        "value": "@split(item().tablename,'.')[0]",
                                                        "type": "Expression"
                                                    },
                                                    "table_name": "@split(item().tablename,'.')[1]"
                                                }
                                            }
                                        ],
                                        "outputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "container": "bronze",
                                                    "file_path": "@item().targetpath",
                                                    "file_name": "@split(item().tablename,'.')[1]"
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "name": "Update_Audit_log_Incremental_load_1",
                                        "type": "Lookup",
                                        "dependsOn": [
                                            {
                                                "activity": "COPY_Incrmental_Load_1",
                                                "dependencyConditions": [
                                                    "Succeeded"
                                                ]
                                            }
                                        ],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureDatabricksDeltaLakeSource",
                                                "query": {
                                                    "value": "@concat('INSERT INTO  audit.load_logs(data_source ,tablename ,numberofrowscopied ,watermarkcolumnname ,loaddate) VALUES(''', item().datasource,''',''',item().tablename,''',''',activity('COPY_Incrmental_Load').output.rowscopied,''',''',item().watermark,''',''',utcNOW(),''')')\n",
                                                    "type": "Expression"
                                                }
                                            },
                                            "dataset": {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "schema_name": "'a'",
                                                    "table_name": "'b'"
                                                }
                                            },
                                            "firstRowOnly": false
                                        }
                                    },
                                    {
                                        "name": "Get_Latest_Date_1",
                                        "type": "Lookup",
                                        "dependsOn": [],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureDatabricksDeltaLakeSource",
                                                "query": {
                                                    "value": "@concat('SELECT COALESCE(cast(max(loaddate) as date) ,''','1900-01-01',''')',' as last_fetched_date from audit.load_logs where  data_source = ''',item().datasource,''' and tablename = ''',item().tablename,'''' ) \n",
                                                    "type": "Expression"
                                                }
                                            },
                                            "dataset": {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "schema_name": "'a'",
                                                    "table_name": "'b'"
                                                }
                                            },
                                            "firstRowOnly": true
                                        }
                                    }
                                ],
                                "ifTrueActivities": [
                                    {
                                        "name": "COPY_Full_Load_1",
                                        "type": "Copy",
                                        "dependsOn": [],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureSqlSource",
                                                "sqlReaderQuery": {
                                                    "value": "@concat('SELECT * ,   ''',item().datasource,''' AS datasource from ',item().tablename)",
                                                    "type": "Expression"
                                                },
                                                "queryTimeout": "02:00:00",
                                                "partitionOption": "None"
                                            },
                                            "sink": {
                                                "type": "ParquetSink",
                                                "storeSettings": {
                                                    "type": "AzureBlobFSWriteSettings"
                                                },
                                                "formatSettings": {
                                                    "type": "ParquetWriteSettings"
                                                }
                                            },
                                            "enableStaging": false,
                                            "translator": {
                                                "type": "TabularTranslator",
                                                "typeConversion": true,
                                                "typeConversionSettings": {
                                                    "allowDataTruncation": true,
                                                    "treatBooleanAsNumber": false
                                                }
                                            }
                                        },
                                        "inputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "db_name": {
                                                        "value": "@item().database",
                                                        "type": "Expression"
                                                    },
                                                    "schema_name": {
                                                        "value": "@split(item().tablename,'.')[0]",
                                                        "type": "Expression"
                                                    },
                                                    "table_name": "@split(item().tablename,'.')[1]"
                                                }
                                            }
                                        ],
                                        "outputs": [
                                            {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "container": "bronze",
                                                    "file_path": "@item().targetpath",
                                                    "file_name": "@split(item().tablename,'.')[1]"
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "name": "Update_Audit_log_Full_load_1",
                                        "type": "Lookup",
                                        "dependsOn": [
                                            {
                                                "activity": "COPY_Full_Load_1",
                                                "dependencyConditions": [
                                                    "Succeeded"
                                                ]
                                            }
                                        ],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "AzureDatabricksDeltaLakeSource",
                                                "query": {
                                                    "value": "@concat('INSERT INTO  audit.load_logs(data_source ,tablename ,numberofrowscopied ,watermarkcolumnname ,loaddate) VALUES(''', item().datasource,''',''',item().tablename,''',''',activity('COPY_Full_Load').output.rowscopied,''',''',item().watermark,''',''',utcNOW(),''')')\n",
                                                    "type": "Expression"
                                                }
                                            },
                                            "dataset": {
                                                "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                "type": "DatasetReference",
                                                "parameters": {
                                                    "schema_name": "'a'",
                                                    "table_name": "'b'"
                                                }
                                            },
                                            "firstRowOnly": false
                                        }
                                    }
                                ]
                            }
                        },
                        {
                            "name": "Switch_Loads",
                            "type": "Switch",
                            "dependsOn": [
                                {
                                    "activity": "IF_File_Exists",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "on": {
                                    "value": "@variables('Is_Archived')",
                                    "type": "Expression"
                                },
                                "cases": [
                                    {
                                        "value": "True_Full",
                                        "activities": [
                                            {
                                                "name": "COPY_Full_Load",
                                                "type": "Copy",
                                                "dependsOn": [],
                                                "policy": {
                                                    "timeout": "0.12:00:00",
                                                    "retry": 0,
                                                    "retryIntervalInSeconds": 30,
                                                    "secureOutput": false,
                                                    "secureInput": false
                                                },
                                                "userProperties": [],
                                                "typeProperties": {
                                                    "source": {
                                                        "type": "AzureSqlSource",
                                                        "sqlReaderQuery": {
                                                            "value": "@concat('SELECT * ,   ''',item().datasource,''' AS datasource from ',item().tablename)",
                                                            "type": "Expression"
                                                        },
                                                        "queryTimeout": "02:00:00",
                                                        "partitionOption": "None"
                                                    },
                                                    "sink": {
                                                        "type": "ParquetSink",
                                                        "storeSettings": {
                                                            "type": "AzureBlobFSWriteSettings"
                                                        },
                                                        "formatSettings": {
                                                            "type": "ParquetWriteSettings"
                                                        }
                                                    },
                                                    "enableStaging": false,
                                                    "translator": {
                                                        "type": "TabularTranslator",
                                                        "typeConversion": true,
                                                        "typeConversionSettings": {
                                                            "allowDataTruncation": true,
                                                            "treatBooleanAsNumber": false
                                                        }
                                                    }
                                                },
                                                "inputs": [
                                                    {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "db_name": {
                                                                "value": "@item().database",
                                                                "type": "Expression"
                                                            },
                                                            "schema_name": {
                                                                "value": "@split(item().tablename,'.')[0]",
                                                                "type": "Expression"
                                                            },
                                                            "table_name": "@split(item().tablename,'.')[1]"
                                                        }
                                                    }
                                                ],
                                                "outputs": [
                                                    {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "container": "bronze",
                                                            "file_path": "@item().targetpath",
                                                            "file_name": "@split(item().tablename,'.')[1]"
                                                        }
                                                    }
                                                ]
                                            },
                                            {
                                                "name": "Update_Audit_log_Full_load",
                                                "type": "Lookup",
                                                "dependsOn": [
                                                    {
                                                        "activity": "COPY_Full_Load",
                                                        "dependencyConditions": [
                                                            "Succeeded"
                                                        ]
                                                    }
                                                ],
                                                "policy": {
                                                    "timeout": "0.12:00:00",
                                                    "retry": 0,
                                                    "retryIntervalInSeconds": 30,
                                                    "secureOutput": false,
                                                    "secureInput": false
                                                },
                                                "userProperties": [],
                                                "typeProperties": {
                                                    "source": {
                                                        "type": "AzureDatabricksDeltaLakeSource",
                                                        "query": {
                                                            "value": "@concat('INSERT INTO  audit.load_logs(data_source ,tablename ,numberofrowscopied ,watermarkcolumnname ,loaddate) VALUES(''', item().datasource,''',''',item().tablename,''',''',activity('COPY_Full_Load').output.rowscopied,''',''',item().watermark,''',''',utcNOW(),''')')\n",
                                                            "type": "Expression"
                                                        }
                                                    },
                                                    "dataset": {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "schema_name": "'a'",
                                                            "table_name": "'b'"
                                                        }
                                                    },
                                                    "firstRowOnly": false
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "value": "True_Incremental",
                                        "activities": [
                                            {
                                                "name": "COPY_Incrmental_Load",
                                                "type": "Copy",
                                                "dependsOn": [
                                                    {
                                                        "activity": "Get_Latest_Date",
                                                        "dependencyConditions": [
                                                            "Succeeded"
                                                        ]
                                                    }
                                                ],
                                                "policy": {
                                                    "timeout": "0.12:00:00",
                                                    "retry": 0,
                                                    "retryIntervalInSeconds": 30,
                                                    "secureOutput": false,
                                                    "secureInput": false
                                                },
                                                "userProperties": [],
                                                "typeProperties": {
                                                    "source": {
                                                        "type": "AzureSqlSource",
                                                        "sqlReaderQuery": {
                                                            "value": "@concat('SELECT * ,   ''',item().datasource,''' AS datasource from ',item().tablename,' where ',item().watermark,'>= ''',activity('Get_Latest_Date').output.firstRow.last_fetched_date,'''')",
                                                            "type": "Expression"
                                                        },
                                                        "queryTimeout": "02:00:00",
                                                        "partitionOption": "None"
                                                    },
                                                    "sink": {
                                                        "type": "ParquetSink",
                                                        "storeSettings": {
                                                            "type": "AzureBlobFSWriteSettings"
                                                        },
                                                        "formatSettings": {
                                                            "type": "ParquetWriteSettings"
                                                        }
                                                    },
                                                    "enableStaging": false,
                                                    "translator": {
                                                        "type": "TabularTranslator",
                                                        "typeConversion": true,
                                                        "typeConversionSettings": {
                                                            "allowDataTruncation": true,
                                                            "treatBooleanAsNumber": false
                                                        }
                                                    }
                                                },
                                                "inputs": [
                                                    {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_sqldb_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "db_name": {
                                                                "value": "@item().database",
                                                                "type": "Expression"
                                                            },
                                                            "schema_name": {
                                                                "value": "@split(item().tablename,'.')[0]",
                                                                "type": "Expression"
                                                            },
                                                            "table_name": "@split(item().tablename,'.')[1]"
                                                        }
                                                    }
                                                ],
                                                "outputs": [
                                                    {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_parquet_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "container": "bronze",
                                                            "file_path": "@item().targetpath",
                                                            "file_name": "@split(item().tablename,'.')[1]"
                                                        }
                                                    }
                                                ]
                                            },
                                            {
                                                "name": "Update_Audit_log_Incremental_load",
                                                "type": "Lookup",
                                                "dependsOn": [
                                                    {
                                                        "activity": "COPY_Incrmental_Load",
                                                        "dependencyConditions": [
                                                            "Succeeded"
                                                        ]
                                                    }
                                                ],
                                                "policy": {
                                                    "timeout": "0.12:00:00",
                                                    "retry": 0,
                                                    "retryIntervalInSeconds": 30,
                                                    "secureOutput": false,
                                                    "secureInput": false
                                                },
                                                "userProperties": [],
                                                "typeProperties": {
                                                    "source": {
                                                        "type": "AzureDatabricksDeltaLakeSource",
                                                        "query": {
                                                            "value": "@concat('INSERT INTO  audit.load_logs(data_source ,tablename ,numberofrowscopied ,watermarkcolumnname ,loaddate) VALUES(''', item().datasource,''',''',item().tablename,''',''',activity('COPY_Incrmental_Load').output.rowscopied,''',''',item().watermark,''',''',utcNOW(),''')')\n",
                                                            "type": "Expression"
                                                        }
                                                    },
                                                    "dataset": {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "schema_name": "'a'",
                                                            "table_name": "'b'"
                                                        }
                                                    },
                                                    "firstRowOnly": false
                                                }
                                            },
                                            {
                                                "name": "Get_Latest_Date",
                                                "type": "Lookup",
                                                "dependsOn": [],
                                                "policy": {
                                                    "timeout": "0.12:00:00",
                                                    "retry": 0,
                                                    "retryIntervalInSeconds": 30,
                                                    "secureOutput": false,
                                                    "secureInput": false
                                                },
                                                "userProperties": [],
                                                "typeProperties": {
                                                    "source": {
                                                        "type": "AzureDatabricksDeltaLakeSource",
                                                        "query": {
                                                            "value": "@concat('SELECT COALESCE(cast(max(loaddate) as date) ,''','1900-01-01',''')',' as last_fetched_date from audit.load_logs where  data_source = ''',item().datasource,''' and tablename = ''',item().tablename,'''' ) \n",
                                                            "type": "Expression"
                                                        }
                                                    },
                                                    "dataset": {
                                                        "referenceName": "${var.resource_group_name_prefix}_${var.proj_name_prefix}_${var.env_prefix}_generic_dl_ds",
                                                        "type": "DatasetReference",
                                                        "parameters": {
                                                            "schema_name": "'a'",
                                                            "table_name": "'b'"
                                                        }
                                                    },
                                                    "firstRowOnly": true
                                                }
                                            }
                                        ]
                                    }
                                ]
                            }
                        }
                    ]
                }
            },
            {
                "name": "Execute_Active_Tables",
                "type": "ExecutePipeline",
                "dependsOn": [],
                "policy": {
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "pl_active_tables",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true
                }
            }
]
  JSON
}


resource "azurerm_data_factory_pipeline" "vj_rcm_adb_etl_pl" {
  name            = "pl_adb_etl"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  activities_json = <<JSON
[


            {
                "name": "slv_transactions",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/Transactions"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_transactions",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_transactions",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/fact_transaction"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_departments",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/Departments_F"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_departments",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_departments",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/dim_department"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_patient",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/Patient"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_patient",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_patient",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/dim_patient"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_npi",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/NPI"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_npi",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_npi",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/dim_npi"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_icd_code",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/ICD Code"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_icd_code",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_icd_code",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/dim_icd_code"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_provider",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/Providers_F"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_provider",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_provider",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/dim_provider"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_cpt_codes",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/CPT codes"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_cpt_codes",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "slv_cpt_codes",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/dim_cpt_code"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_encounters",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/Encounters"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "slv_claims",
                "type": "DatabricksNotebook",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/3. Silver/Claims"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "gld_output",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "gld_transactions",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "gld_departments",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "gld_provider",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Users/${data.databricks_current_user.me.home}/4. Gold/business_logic"
                },
                "linkedServiceName": {
                    "referenceName": "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-ls",
                    "type": "LinkedServiceReference"
                }
            }
    ]
  JSON
}



resource "azurerm_data_factory_pipeline" "vj_rcm_master_pipeline_pl" {
  name            = "Master_Pipeline"
  data_factory_id = azurerm_data_factory.rcm_adf.id
  activities_json = <<JSON
[
            {
                "name": "Execute_pl_etl",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "Execute_pl_ingestion",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "pl_adb_etl",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true
                }
            },
            {
                "name": "Execute_pl_ingestion",
                "type": "ExecutePipeline",
                "dependsOn": [],
                "policy": {
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "pl_emr_src_to_adls",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true
                }
            }


    ]
  JSON
}

# resource "azapi_update_resource" "vj_rcm_active_tables_pl_update" {
#   type      = "Microsoft.DataFactory/factories/pipelines@2018-06-01"
#   name      = azurerm_data_factory_pipeline.vj_rcm_active_tables_pl.name
#   parent_id = azurerm_data_factory_pipeline.vj_rcm_active_tables_pl.id


#   body = {
#         variables = {
#             items = var.items
#         }
#   }
# }