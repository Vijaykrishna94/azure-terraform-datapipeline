
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
    subscription_id = "71458d97-9dd7-48da-8513-2222c61f78bf"
    resource_group_name  = "vj-rcm-dev-rg"
    storage_account_name = "vjrcmdevstorage"
    container_name       = "tfstate"
    key                  = "root.terraform.tfstate"
    use_oidc             = true
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}