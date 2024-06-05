
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    # TODO: Ensure all required providers are listed here.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.11.0"
    }
  }
}

provider "azurerm" {
  features {}  
}