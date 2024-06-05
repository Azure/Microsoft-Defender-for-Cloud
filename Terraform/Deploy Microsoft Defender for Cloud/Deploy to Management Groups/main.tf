# Create a custom initiative for Defender for Cloud at Scale deployment
resource "azurerm_policy_set_definition" "MDCAtScale" {
  name         = "Microsoft Defender for Cloud"
  policy_type  = "Custom"
  display_name = "MDC at Scale"
  description  = "This policy set Microosft Defender for Cloud and Microsoft Defender for Cloud features."
  management_group_id  = data.azurerm_management_group.example.id
  metadata    = jsonencode({
    "category": "Security",
    "version": "1.1.0",
     managed_identity = "azurerm_user_assigned_identity.MDCAtScale.principal_id"
  })



## Policy Assignment
##Enable Microsoft Defender for Cloud on the Subscription
 policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ac076320-ddcf-4066-b451-6154267e8ad2"
  }

#Configure CSPM Plan
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/72f8cee7-2937-403d-84a1-a4e3e57f3c21"
  }


##PAAS Deployment features
#Defender for App Service
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b40e7bcd-a1e5-47fe-b9cf-2f534d0bfb7d"
 }


#Defender for Key Vaults
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
}


#Defender for Storage with Malware scanning
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cfdc5972-75b3-4418-8ae1-7f5c36839390"
}


#Defender for Resource Manager 
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b7021b2b-08fd-4dc0-9de7-3c6ece09faf9"
}


#Defender for Containers
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/c9ddb292-b203-4738-aead-18e2716e858f"

}


# Defender for Azure SQL Database
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b99b73e7-074b-4089-9395-b7236f094491"
}


# Defender for Open-Source Relational Database
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/44433aa3-7ec2-4002-93ea-65c65ff0310a"
}


# Defender for Cosmos DB
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/82bf5b87-728b-4a74-ba4d-6123845cf542"
}

#IAAS Deployment features
#Defender for Servers all P2
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8e86a5b6-b9bd-49d1-8e21-4bb8a0862222"
}

#WDATP
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/da56d295-2889-41ce-a4cd-6f50fb93aa68"
}

#WDATP Linux
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f9e2bd2f-47c7-4059-8265-c5292aa62c8a"
}

#WDATP Unifed Winodws 2012R2 and 2016
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/48666c5d-cec1-4043-ab6b-1be05abb24f2"
}

#Defender for Servers to be enabled ('P1' subplan) for resoruces (resource level) with the selected tag
#Comment this one out unless needed
//policy_definition_reference {
// policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/9e4879d9-c2a0-4e40-8017-1a5a5327c843"
//}


# Enable Vulnerability Assessment for Servers
policy_definition_reference {
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/13ce0167-8ca6-4048-8e6b-f996402e3c1b"
}

#Set Up Vulnerability Assessement
policy_definition_reference {
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/766e621d-ba95-4e43-a6f2-e945db3d7888"
}


#Defender for Kubernetes Daemon set
policy_definition_reference {
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/64def556-fbad-4622-930e-72d1d5589bf5"
}

# Deploying Defender extenstion in Azure for Arc Kubernetes
policy_definition_reference {
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/708b60a6-d253-4fe0-9114-4be4c00f012c"
}

#Defender for Kubernetes Add-on policy
 policy_definition_reference {
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a8eff44f-8c92-45c3-a3fb-9880802d67a7"
}


# Defender for SQL Servers
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/50ea7265-7d8c-429e-9a7d-ca1f410191c3"
}


#Auto install AMA Defender for SQL on VMs
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ddca0ddc-4e9d-4bbb-92a1-f7c4dd7ef7ce"
}


#Auto install AMA Defender for SQL on ARC servers
policy_definition_reference {
 policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/65503269-6a54-4553-8a28-0065a8e6d929"
}

 //policy_definition_reference {
   // policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8e7da0a5-0a0e-4bbc-bfc0-7773c018b616"
   // parameter_values = {
 //     logAnalyticsWorkspaceId = var.log_analytics_workspace_id
  //  }
  
//}
}



