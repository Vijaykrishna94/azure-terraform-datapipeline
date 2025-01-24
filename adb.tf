# resource "databricks_token" "pat" {
#   provider = databricks.vj_rcm_ws
#   comment  = "Terraform Provisioning"
#   // 100 day token
#   lifetime_seconds = 8640000
# }