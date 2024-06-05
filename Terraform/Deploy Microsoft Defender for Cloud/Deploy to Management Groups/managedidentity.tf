# Create a system-assigned managed identity
resource "azurerm_user_assigned_identity" "MDCAtScale" {
  name                = "DefenderforCloudAtScale"
  location            = var.location # Replace with your desired location
  resource_group_name = var.resource_group_name
}
# Assigns the Owner permission which is required to enable some extensions and features in Defender for Cloud
resource "azurerm_role_assignment" "owner_assignment" {
  principal_id          = azurerm_user_assigned_identity.MDCAtScale.principal_id
  role_definition_name  = "Owner"
  scope                = var.scope
}
# Assigns the Security Admin role. This role is specific to Azure and is not the Security Administrator that has a larger scope of access
resource "azurerm_role_assignment" "security_admin_assignment" {
  principal_id          = azurerm_user_assigned_identity.MDCAtScale.principal_id
  role_definition_name  = "Security Admin"
  scope                = var.scope
}
