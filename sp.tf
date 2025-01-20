data "azuread_client_config" "ad_current" {}



resource "azuread_application" "rcm_adf_app" {
  display_name = "${var.resource_group_name_prefix}-${var.proj_name_prefix}-${var.env_prefix}-adf-app"
  owners       = [data.azuread_client_config.ad_current.object_id]
}

