terraform {

  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.61"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "=1.6.0"
    }
  }
}

provider "azurerm" {
  features {}
}