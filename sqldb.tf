resource "random_password" "admin_password" {
  count       = var.admin_password == null ? 1 : 0
  length      = 20
  special     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

locals {
  admin_password = try(random_password.admin_password[0].result, var.admin_password)
}





resource "azurerm_mssql_server" "rcm_server" {
  name                         = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}sql"
  resource_group_name          = azurerm_resource_group.rcm_rg.name
  location                     = azurerm_resource_group.rcm_rg.location
  administrator_login          = var.admin_username
  administrator_login_password = local.admin_password
  version                      = "12.0"
}

resource "azurerm_mssql_firewall_rule" "rcm_fw" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.rcm_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "rcm_db" {
  for_each  = toset(["${var.resource_group_name_prefix}-${var.proj_name_prefix}-hos-a", "${var.resource_group_name_prefix}-${var.proj_name_prefix}-hos-b"])
  name      = each.key
  server_id = azurerm_mssql_server.rcm_server.id
}