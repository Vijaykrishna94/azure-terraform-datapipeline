# Retrieve information about the current user.
data "databricks_current_user" "me" {}

####################################################################################### SET UP ###############################################################################################
resource "databricks_notebook" "rcm_audit_ddl_notebook" {
  path     = "${data.databricks_current_user.me.home}/1. Set up/1. audit_ddl.py"
  language = "PYTHON"
  source   = "1. Set up/1. audit_ddl.py"
}

resource "databricks_notebook" "rcm_adls_mount_notebook" {
  path     = "${data.databricks_current_user.me.home}/1. Set up/2. adls_mount.py"
  language = "PYTHON"
  source   = "1. Set up/2. adls_mount.py"
}
