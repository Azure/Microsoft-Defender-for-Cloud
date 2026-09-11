resource "azurerm_policy_definition" "custom_defender_storage" {
  name                = "custom-defender-storage-policy"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "CUSTOM - Configure Microsoft Defender for Storage to be enabled"
  management_group_id = var.management_group_id

  description = "Microsoft Defender for Storage is an Azure-native layer of security intelligence that detects potential threats to your storage accounts. This custom policy will enable all Defender for Storage capabilities with configurable extension properties. This version fixes case-sensitivity issues in the built-in policy."

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
        name              = "StorageAccounts"
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
              equals = "DefenderForStorageV2"
            },
            {
              count = {
                field = "Microsoft.Security/pricings/extensions[*]"
                where = {
                  allOf = [
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].name"
                      equals = "OnUploadMalwareScanning"
                    },
                    {
                      field  = "Microsoft.Security/pricings/extensions[*].isEnabled"
                      equals = "[parameters('isOnUploadMalwareScanningEnabled')]"
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
            }
          ]
        }
        deployment = {
          location = "westeurope"
          properties = {
            mode = "incremental"
            parameters = {
              isOnUploadMalwareScanningEnabled = {
                value = "[parameters('isOnUploadMalwareScanningEnabled')]"
              }
              capGBPerMonthPerStorageAccount = {
                value = "[parameters('capGBPerMonthPerStorageAccount')]"
              }
              automatedResponseOption = {
                value = "[parameters('automatedResponseOption')]"
              }
              blobScanResultsOption = {
                value = "[parameters('blobScanResultsOption')]"
              }
              isSensitiveDataDiscoveryEnabled = {
                value = "[parameters('isSensitiveDataDiscoveryEnabled')]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                isOnUploadMalwareScanningEnabled = {
                  type = "String"
                }
                capGBPerMonthPerStorageAccount = {
                  type = "int"
                }
                automatedResponseOption = {
                  type = "String"
                }
                blobScanResultsOption = {
                  type = "String"
                }
                isSensitiveDataDiscoveryEnabled = {
                  type = "String"
                }
              }
              variables = {
                enabledMalwareScanningExtension = {
                  name      = "OnUploadMalwareScanning"
                  isEnabled = "True"
                  additionalExtensionProperties = {
                    AutomatedResponse              = "[parameters('automatedResponseOption')]"
                    BlobScanResultsOptions         = "[parameters('blobScanResultsOption')]"
                    CapGBPerMonthPerStorageAccount = "[parameters('capGBPerMonthPerStorageAccount')]"
                  }
                }
                disabledMalwareScanningExtension = {
                  name      = "OnUploadMalwareScanning"
                  isEnabled = "False"
                }
                malwareScanningExtension = "[if(equals(toLower(parameters('isOnUploadMalwareScanningEnabled')),'true'), variables('enabledMalwareScanningExtension'), variables('disabledMalwareScanningExtension'))]"
              }
              resources = [
                {
                  type       = "Microsoft.Security/pricings"
                  apiVersion = "2023-01-01"
                  name       = "StorageAccounts"
                  properties = {
                    pricingTier = "Standard"
                    subPlan     = "DefenderForStorageV2"
                    extensions = [
                      "[variables('malwareScanningExtension')]",
                      {
                        name      = "SensitiveDataDiscovery"
                        isEnabled = "[parameters('isSensitiveDataDiscoveryEnabled')]"
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
    isOnUploadMalwareScanningEnabled = {
      type = "String"
      metadata = {
        displayName = "On-Upload Malware Scanning Enabled"
        description = "Enable malware scanning on blob uploads (True/False)"
      }
      allowedValues = [
        "True",
        "False"
      ]
      defaultValue = "True"
    }
    capGBPerMonthPerStorageAccount = {
      type = "Integer"
      metadata = {
        displayName = "Cap GB Per Month Per Storage Account"
        description = "Limit the GB scanned per month for each storage account. Minimum value is 10. Set to -1 for unlimited scanning"
      }
      defaultValue = 10
    }
    automatedResponseOption = {
      type = "String"
      metadata = {
        displayName = "Automated Response Option"
        description = "Automated response for malware scanning findings (None or BlobSoftDelete)"
      }
      allowedValues = [
        "None",
        "BlobSoftDelete"
      ]
      defaultValue = "BlobSoftDelete"
    }
    blobScanResultsOption = {
      type = "String"
      metadata = {
        displayName = "Blob Scan Results Option"
        description = "Where to store blob scan results"
      }
      allowedValues = [
        "BlobIndexTags",
        "None"
      ]
      defaultValue = "None"
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
  })
}
