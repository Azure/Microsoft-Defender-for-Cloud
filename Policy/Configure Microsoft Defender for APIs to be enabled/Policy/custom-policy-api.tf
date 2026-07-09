resource "azurerm_policy_definition" "custom_defender_api" {
  name                = "custom-defender-api-policy"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "CUSTOM - Configure Microsoft Defender for APIs to be enabled"
  management_group_id = var.management_group_id

  description = "Microsoft Defender for APIs brings discovery, protection, detection, and response coverage to monitor common API-based attacks and security misconfigurations."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Security Center"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/subscriptions"
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        type              = "Microsoft.Security/pricings"
        name              = "Api"
        deploymentScope   = "subscription"
        existenceScope    = "subscription"
        roleDefinitionIds = ["/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"]
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Security/pricings/pricingTier"
              equals = "Standard"
            },
            {
              field  = "Microsoft.Security/pricings/subPlan"
              equals = "[parameters('subPlan')]"
            }
          ]
        }
        deployment = {
          location = "westeurope"
          properties = {
            mode = "incremental"
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                subPlan = {
                  type = "string"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Security/pricings"
                  apiVersion = "2024-01-01"
                  name       = "Api"
                  properties = {
                    pricingTier = "Standard"
                    subPlan     = "[parameters('subPlan')]"
                  }
                }
              ]
              outputs = {}
            }
            parameters = {
              subPlan = {
                value = "[parameters('subPlan')]"
              }
            }
          }
        }
      }
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = [
        "DeployIfNotExists",
        "Disabled"
      ]
      defaultValue = "DeployIfNotExists"
    }
    subPlan = {
      type = "String"
      metadata = {
        displayName = "API pricing plan"
        description = "Pricing plan for Defender for APIs."
      }
      allowedValues = [
        "P1",
        "P2",
        "P3",
        "P4",
        "P5"
      ]
      defaultValue = "P1"
    }
  })
}
