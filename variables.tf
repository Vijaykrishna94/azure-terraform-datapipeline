variable "resource_group_location" {
  type        = string
  default     = "swedencentral"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "vj"
  description = "Prefix of the resource group name in your Azure subscription."
}

variable "proj_name_prefix" {
  type        = string
  default     = "rcm"
  description = "Prefix of the proj name in your Azure subscription."
}


variable "env_prefix" {
  type        = string
  default     = "dev"
  description = "Prefix of the env name in your Azure subscription."
}

variable "admin_username" {
  type        = string
  description = "The administrator username of the SQL logical server."
  default     = "azuresqladmin"
}

variable "admin_password" {
  type        = string
  description = "The administrator password of the SQL logical server."
  sensitive   = true
  default     = null
}



variable "cluster_name" {
  description = "A name for the cluster."
  type        = string
  default     = "${var.resource_group_name_prefix}${var.proj_name_prefix}${var.env_prefix}cluster"
}

variable "cluster_autotermination_minutes" {
  description = "How many minutes before automatically terminating due to inactivity."
  type        = number
  default     = 60
}

variable "cluster_num_workers" {
  description = "The number of workers."
  type        = number
  default     = 1
}