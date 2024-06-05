# This adds the policy assignment with the Defender for Cloud scale operations to your desired scope
resource "azurerm_management_group_policy_assignment" "MDCatScale_assignment" {
  name = "MDC at Scale"
  management_group_id  = data.azurerm_management_group.example.id
  policy_definition_id = "/providers/Microsoft.Management/managementGroups/Production/providers/Microsoft.Authorization/policySetDefinitions/Microsoft Defender for Cloud" 
  #NOTE Change the Management Group Name
  display_name = "MDC at Scale"
   location = var.location
  identity {
      type        = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.MDCAtScale.id]
  }
}

# This enables the new Microsoft Cloud Security Benchmark recommendations to your Subscriptions
resource "azurerm_management_group_policy_assignment" "mcsb_assignment" {
  name                 = "mcsb"
  display_name         = "Microsoft Cloud Security Benchmark"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  management_group_id  = data.azurerm_management_group.example.id
   location = var.location
  identity {
    type        = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.MDCAtScale.id]
  }
}