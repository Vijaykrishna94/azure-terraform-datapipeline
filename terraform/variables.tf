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