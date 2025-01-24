data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}


output "node_type" {
    value = data.databricks_node_type.smallest
  
}




output "spark_version" {
    value = data.databricks_spark_version.latest_lts
  
}