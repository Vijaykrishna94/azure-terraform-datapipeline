data "azuread_client_config" "ad_current" {}


resource "azuread_application_registration" "rcm_adf_app" {
  display_name = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adf-app"
  
}

resource "azuread_service_principal" "azure_adf_sp" {
  client_id = azuread_application_registration.rcm_adf_app.client_id
  use_existing   = true
}
