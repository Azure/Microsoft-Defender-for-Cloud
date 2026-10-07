resource "azurerm_policy_definition" "custom_defender_cspm" {
  name                = "custom-defender-cspm-policy"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "CUSTOM - Configure Microsoft Defender CSPM plan"
  management_group_id = var.management_group_id

  description = "Microsoft Defender for Cloud Posture Management (CSPM) continuously discovers and scores your cloud environment. This custom policy enables all CSPM capabilities with configurable extensions including those not available in the built-in policy (ApiPosture, AgentlessServerlessPosture, ServerlessContainers, DatabricksSecurityPosture)."

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
        name              = "CloudPosture"
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
              count = {
                field = "Microsoft.Security/pricings/extensions[*]"
                where = {
                  allOf = [
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].name"
                      equals = "SensitiveDataDiscovery"
                    },
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].isEnabled"
                      equals = "[parameters('isSensitiveDataDiscoveryEnabled')]"
                    }
                  ]
                }
              }
              equals = 1
            },
            {
              count = {
                field = "Microsoft.Security/pricings/extensions[*]"
                where = {
                  allOf = [
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].name"
                      equals = "ContainerRegistriesVulnerabilityAssessments"
                    },
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].isEnabled"
                      equals = "[parameters('isContainerRegistriesVulnerabilityAssessmentsEnabled')]"
                    }
                  ]
                }
              }
              equals = 1
            },
            {
              count = {
                field = "Microsoft.Security/pricings/extensions[*]"
                where = {
                  allOf = [
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].name"
                      equals = "AgentlessDiscoveryForKubernetes"
                    },
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].isEnabled"
                      equals = "[parameters('isAgentlessDiscoveryForKubernetesEnabled')]"
                    }
                  ]
                }
              }
              equals = 1
            },
            {
              count = {
                field = "Microsoft.Security/pricings/extensions[*]"
                where = {
                  allOf = [
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].name"
                      equals = "AgentlessServerlessPosture"
                    },
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].isEnabled"
                      equals = "[parameters('isAgentlessServerlessPostureEnabled')]"
                    }
                  ]
                }
              }
              equals = 1
            }
          ]
        }
        deployment = {
          location = "westeurope"
          properties = {
            mode = "incremental"
            parameters = {
              isSensitiveDataDiscoveryEnabled = {
                value = "[parameters('isSensitiveDataDiscoveryEnabled')]"
              }
              isContainerRegistriesVulnerabilityAssessmentsEnabled = {
                value = "[parameters('isContainerRegistriesVulnerabilityAssessmentsEnabled')]"
              }
              isAgentlessDiscoveryForKubernetesEnabled = {
                value = "[parameters('isAgentlessDiscoveryForKubernetesEnabled')]"
              }
              isAgentlessVmScanningEnabled = {
                value = "[parameters('isAgentlessVmScanningEnabled')]"
              }
              isEntraPermissionsManagementEnabled = {
                value = "[parameters('isEntraPermissionsManagementEnabled')]"
              }
              isApiPostureEnabled = {
                value = "[parameters('isApiPostureEnabled')]"
              }
              isAgentlessServerlessPostureEnabled = {
                value = "[parameters('isAgentlessServerlessPostureEnabled')]"
              }
              isServerlessContainersEnabled = {
                value = "[parameters('isServerlessContainersEnabled')]"
              }
              isDatabricksSecurityPostureEnabled = {
                value = "[parameters('isDatabricksSecurityPostureEnabled')]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                isSensitiveDataDiscoveryEnabled = {
                  type = "String"
                }
                isContainerRegistriesVulnerabilityAssessmentsEnabled = {
                  type = "String"
                }
                isAgentlessDiscoveryForKubernetesEnabled = {
                  type = "String"
                }
                isAgentlessVmScanningEnabled = {
                  type = "String"
                }
                isEntraPermissionsManagementEnabled = {
                  type = "String"
                }
                isApiPostureEnabled = {
                  type = "String"
                }
                isAgentlessServerlessPostureEnabled = {
                  type = "String"
                }
                isServerlessContainersEnabled = {
                  type = "String"
                }
                isDatabricksSecurityPostureEnabled = {
                  type = "String"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Security/pricings"
                  apiVersion = "2023-01-01"
                  name       = "CloudPosture"
                  properties = {
                    pricingTier = "Standard"
                    extensions = [
                      {
                        name      = "SensitiveDataDiscovery"
                        isEnabled = "[parameters('isSensitiveDataDiscoveryEnabled')]"
                      },
                      {
                        name      = "ContainerRegistriesVulnerabilityAssessments"
                        isEnabled = "[parameters('isContainerRegistriesVulnerabilityAssessmentsEnabled')]"
                      },
                      {
                        name      = "AgentlessDiscoveryForKubernetes"
                        isEnabled = "[parameters('isAgentlessDiscoveryForKubernetesEnabled')]"
                      },
                      {
                        name      = "AgentlessVmScanning"
                        isEnabled = "[parameters('isAgentlessVmScanningEnabled')]"
                      },
                      {
                        name      = "EntraPermissionsManagement"
                        isEnabled = "[parameters('isEntraPermissionsManagementEnabled')]"
                      },
                      {
                        name      = "ApiPosture"
                        isEnabled = "[parameters('isApiPostureEnabled')]"
                      },
                      {
                        name      = "AgentlessServerlessPosture"
                        isEnabled = "[parameters('isAgentlessServerlessPostureEnabled')]"
                      },
                      {
                        name      = "ServerlessContainers"
                        isEnabled = "[parameters('isServerlessContainersEnabled')]"
                      },
                      {
                        name      = "DatabricksSecurityPosture"
                        isEnabled = "[parameters('isDatabricksSecurityPostureEnabled')]"
                      }
                    ]
                  }
                }
              ]
              outputs = {}
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
        description = "The effect determines what happens when the policy rule is evaluated to match"
      }
      allowedValues = [
        "DeployIfNotExists",
        "AuditIfNotExists",
        "Disabled"
      ]
      defaultValue = "DeployIfNotExists"
    }
    isSensitiveDataDiscoveryEnabled = {
      type = "String"
      metadata = {
        displayName = "Sensitive Data Discovery Enabled"
        description = "Enable sensitive data discovery (True/False)"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isContainerRegistriesVulnerabilityAssessmentsEnabled = {
      type = "String"
      metadata = {
        displayName = "Container Registries Vulnerability Assessments Enabled"
        description = "Enable vulnerability assessments for container registries (True/False)"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isAgentlessDiscoveryForKubernetesEnabled = {
      type = "String"
      metadata = {
        displayName = "Agentless Discovery For Kubernetes Enabled"
        description = "Enable agentless discovery for Kubernetes (True/False)"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isAgentlessVmScanningEnabled = {
      type = "String"
      metadata = {
        displayName = "Agentless VM Scanning Enabled"
        description = "Enable agentless VM scanning (True/False)"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isEntraPermissionsManagementEnabled = {
      type = "String"
      metadata = {
        displayName = "Entra Permissions Management Enabled"
        description = "Enable Entra Permissions Management (True/False)"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isApiPostureEnabled = {
      type = "String"
      metadata = {
        displayName = "API Posture Enabled"
        description = "Enable API posture management (True/False) - NOT in built-in policy"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isAgentlessServerlessPostureEnabled = {
      type = "String"
      metadata = {
        displayName = "Agentless Serverless Posture Enabled"
        description = "Enable agentless serverless posture management (True/False) - NOT in built-in policy"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isServerlessContainersEnabled = {
      type = "String"
      metadata = {
        displayName = "Serverless Containers Enabled"
        description = "Enable serverless containers scanning (True/False) - NOT in built-in policy"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    isDatabricksSecurityPostureEnabled = {
      type = "String"
      metadata = {
        displayName = "Databricks Security Posture Enabled"
        description = "Enable Databricks security posture management (True/False) - NOT in built-in policy"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "False"
    }
  })
}
