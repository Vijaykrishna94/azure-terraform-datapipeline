// create PAT token to provision entities within workspace
resource "databricks_token" "pat" {
  provider = databricks.workspace
  comment  = "Terraform Provisioning"
  // 100 day token
  lifetime_seconds = 8640000
}