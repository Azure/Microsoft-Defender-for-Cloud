terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.2.0"
    }
  }
}

provider "azapi" {
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "security_connectors_resource_group" {
  name     = var.mdc_azure_resource_group_name
  location = var.mdc_azure_resource_group_location
}

module "awsConnector" {
  source                            = "./Modules/security_connector_aws"
  count                             = var.mdc_cloud_type == "AWS" ? length(var.account_id_or_project_number) : 0
  mdc_offerings                     = var.mdc_offerings
  account_id                        = var.account_id_or_project_number[count.index]
  connector_name                    = "${var.mdc_azure_security_connector_name}_${var.account_id_or_project_number[count.index]}"
  mdc_azure_resource_group_location = azurerm_resource_group.security_connectors_resource_group.location
  mdc_azure_resource_group_id       = azurerm_resource_group.security_connectors_resource_group.id
  mdc_connector_tags                = var.mdc_connector_tags

}

module "gcpConnector" {
  source                            = "./Modules/security_connector_gcp"
  count                             = var.mdc_cloud_type == "GCP" ? length(var.account_id_or_project_number) : 0
  mdc_offerings                     = var.mdc_offerings
  project_number                    = var.account_id_or_project_number[count.index]
  project_name                      = var.gcp_project_names[count.index]
  connector_name                    = "${var.mdc_azure_security_connector_name}_${var.account_id_or_project_number[count.index]}"
  mdc_azure_resource_group_location = azurerm_resource_group.security_connectors_resource_group.location
  mdc_azure_resource_group_id       = azurerm_resource_group.security_connectors_resource_group.id
  mdc_connector_tags                = var.mdc_connector_tags

}

