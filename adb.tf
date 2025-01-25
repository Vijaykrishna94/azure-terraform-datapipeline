resource "databricks_token" "pat" {
  comment  = "Terraform Provisioning"
  // 100 day token
  lifetime_seconds = 8640000
    depends_on = [
     azurerm_databricks_workspace.rcm_adb
  ]
}





# Create the cluster with the "smallest" amount
# of resources allowed.
data "databricks_node_type" "smallest" {
  local_disk = true
}

# Use the latest Databricks Runtime
# Long Term Support (LTS) version.
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "rcm_adb_cluster" {
  cluster_name            = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}cluster"
  node_type_id            = data.databricks_node_type.smallest.id
  spark_version           = data.databricks_spark_version.latest_lts.id
  autotermination_minutes = var.cluster_autotermination_minutes
  num_workers             = var.cluster_num_workers
}

output "cluster_url" {
 value = databricks_cluster.rcm_adb_cluster.url
}