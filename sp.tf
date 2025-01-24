data "azuread_client_config" "ad_current" {}


resource "azuread_application_registration" "rcm_adf_app" {
  display_name = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adf-app"

}

resource "azuread_service_principal" "azure_adf_sp" {
  client_id    = azuread_application_registration.rcm_adf_app.client_id
  use_existing = true
  
}



resource "azuread_application_registration" "rcm_adls_app" {
  display_name = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adls-app"

}

resource "azuread_service_principal" "azure_adls_sp" {
  client_id    = azuread_application_registration.rcm_adls_app.client_id
  use_existing = true
}



#Creating ADB Application
resource "azuread_application" "rcm_adb_app" {
  display_name = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adb-app"
}

resource "azuread_service_principal" "rcm_adb_sp" {
  client_id = azuread_application.rcm_adb_app.client_id
}


#creating adb rotation policy for key
resource "time_rotating" "month" {
  rotation_days = 45
}




resource "azuread_service_principal_password" "rcm_adb_pass" {
  service_principal_id = azuread_service_principal.rcm_adb_sp.id
  rotate_when_changed  = { rotation = time_rotating.month.id }
  depends_on = [ azuread_service_principal.rcm_adb_sp,time_rotating.month ]
}


# Mapping (Registering) azuread-db sp

resource "databricks_service_principal" "rcm_db_sp" {
  application_id = azuread_application.rcm_adb_app.client_id
  display_name   = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-azureadb-app"
  depends_on = [ azuread_application.rcm_adb_app ]
}