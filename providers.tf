
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
      version = ">= 3.0.0"
    }
    azapi = {
      source = "azure/azapi"
    }

  }
  backend "azurerm" {
    resource_group_name  = "vj-terraform-rg"
    storage_account_name = "vjterraformstorage"
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
  use_oidc = true
}


# Configure the Azure Active Directory Provider
provider "databricks" {
  host = azurerm_databricks_workspace.rcm_adb.workspace_url
}

provider "azapi" {
  use_oidc = true
}