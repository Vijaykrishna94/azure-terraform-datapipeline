
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "vj-rcm-dev-rg"
    storage_account_name = "vjrcmdevstorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  use_oidc = true
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}
