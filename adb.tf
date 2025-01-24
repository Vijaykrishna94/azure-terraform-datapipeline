resource "databricks_token" "pat" {
  comment  = "Terraform Provisioning"
  // 100 day token
  lifetime_seconds = 8640000
    depends_on = [
     azurerm_databricks_workspace.rcm_adb
  ]
}