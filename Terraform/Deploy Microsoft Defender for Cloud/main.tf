data "azurerm_subscription" "current" {}

## Policy Assignment

resource "azurerm_subscription_policy_assignment" "mcsb_assignment" {
  name                 = "mcsb"
  display_name         = "Microsoft Cloud Security Benchmark"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  subscription_id      = data.azurerm_subscription.current.id
}
# Enable Vulnerability Assessment for Servers
resource "azurerm_subscription_policy_assignment" "va_assignment" {
  name                 = "vuln-assess-servers"
  display_name         = "Vulnerbility Assessment for Machines"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/13ce0167-8ca6-4048-8e6b-f996402e3c1b"
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location
  identity {
    type = "SystemAssigned"
  }
}
# Deploying Defender agent in Azure for Kubernetes
resource "azurerm_subscription_policy_assignment" "def_profile" {
  name                 = "defender-profile"
  display_name         = "Defender Profile"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/64def556-fbad-4622-930e-72d1d5589bf5"
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location
  identity {
    type = "SystemAssigned"
  }
}
# Deploying Defender agent in Azure for Arc Kubernetes
resource "azurerm_subscription_policy_assignment" "arc_def_profile" {
  name                 = "arc-defender-profile"
  display_name         = "Arc Defender Profile"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/708b60a6-d253-4fe0-9114-4be4c00f012c"
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location
  identity {
    type = "SystemAssigned"
  }
}
## Enable Defender for CSPM
resource "azurerm_security_center_subscription_pricing" "mdc_cspm" {
  tier          = "Standard"
  resource_type = "CloudPosture"
  extension {
    name = "ContainerRegistriesVulnerabilityAssessments"
  }
  extension {
    name = "AgentlessVmScanning"
    additional_extension_properties = {
      ExclusionTags = "[]"
    }
  }
  extension {
    name = "AgentlessDiscoveryForKubernetes"
  }
  extension {
    name = "SensitiveDataDiscovery"
  }
  extension {
    name = "EntraPermissionsManagement"
  }
}
## Defender for Servers w/ subplan P2 (P1 and P2 are options))
resource "azurerm_security_center_subscription_pricing" "mdc_servers" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
  subplan       = "P2"
  extension {
    name = "AgentlessVMScanning"
  }
  extension {
    name = "MdeDesignatedSubscription"
  }
}
## Enable Bidrectional Sync between MCAS and MDC
resource "azurerm_security_center_setting" "MCAS" {
  setting_name = "MCAS"
  enabled      = true
}
## Enable Defender for Endpoint Security settings
resource "azurerm_security_center_setting" "WDATP" {
  setting_name = "WDATP"
  enabled      = true
}
## Enable Unified agent deployment for Windows 2012R2 and Windows 2016
resource "azurerm_security_center_setting" "WDATP_UNIFIED_SOLUTION" {
  setting_name = "WDATP_UNIFIED_SOLUTION"
  enabled      = true
}
## Enable Defender for SQL Servers 
resource "azurerm_security_center_subscription_pricing" "mdc_sqlservers" {
  tier          = "Standard"
  resource_type = "SqlServers"
}
## Enable Defender for App Services
resource "azurerm_security_center_subscription_pricing" "mdc_appservices" {
  tier          = "Standard"
  resource_type = "AppServices"
}
## Enable Defender for Storage
resource "azurerm_security_center_subscription_pricing" "mdc_storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
  subplan       = "DefenderForStorageV2"
  extension {
    name = "OnUploadMalwareScanning"
  }
  extension {
    name = "SensitiveDataDiscovery"
  }
}
## Defender for Azure Resource Manager
resource "azurerm_security_center_subscription_pricing" "mdc_arm" {
  tier          = "Standard"
  resource_type = "Arm"
  subplan       = "PerApiCall"
}
## Enable Defender for Key Vaults
resource "azurerm_security_center_subscription_pricing" "mdc_keyvaults" {
  tier          = "Standard"
  resource_type = "KeyVaults"
}
## Enable Defender for Open Source Relational Databases
resource "azurerm_security_center_subscription_pricing" "mdc_OpenSourceRelationalDatabases" {
  tier          = "Standard"
  resource_type = "OpenSourceRelationalDatabases"
}
## Enable Defender for Containters
resource "azurerm_security_center_subscription_pricing" "mdc_Containers" {
  tier          = "Standard"
  resource_type = "Containers"
  extension {
    name = "ContainerRegistriesVulnerabilityAssessments"
  }
}
## Enable Defender for API w/ subplan 1 (P1, P2, P3, P4 and P5 are options)
resource "azurerm_security_center_subscription_pricing" "MDAPI" {
  tier          = "Standard"
  resource_type = "Api"
  subplan       = "P1"
}
## Enable Auto Provisioning of Log Analyitcs Agent
resource "azurerm_security_center_auto_provisioning" "auto_provision" {
  auto_provision = "On"
}

# Security Contacts
resource "azurerm_security_center_contact" "mdc_contact" {
  email               = var.email
  phone               = var.phonenumber
  alert_notifications = true
  alerts_to_admins    = true
}
