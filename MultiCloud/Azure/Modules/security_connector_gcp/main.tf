terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.2.0"
    }
  }
}

locals {

  gcp_service_account_email = "@${var.project_name}.iam.gserviceaccount.com"

  //cspm monitor
  cspm_gcp = {
    offeringType = "CspmMonitorGcp",
    nativeCloudConnection = {
      serviceAccountEmailAddress = "${var.cspm_gcp_service_account_name}${local.gcp_service_account_email}"
      workloadIdentityProviderId = var.cspm_gcp_workload_identity_provider_id
    }
  }

  //defender cspm
  defender_cspm_gcp = {
    offeringType = "DefenderCspmGcp"
  }

  //defender for servers
  defender_servers_gcp = {
    offeringType = "DefenderForServersGcp"
    arcAutoProvisioning = {
      enabled       = true
      configuration = {}

    }
    defenderForServers = {
      serviceAccountEmailAddress = "${var.defender_servers_gcp_service_account_name}${local.gcp_service_account_email}"
      workloadIdentityProviderId = var.defender_servers_workload_identity_provider_id
    }
    mdeAutoProvisioning = {
      enabled       = true
      configuration = {}
    }
    subPlan = var.defender_servers_sub_plan
    vaAutoProvisioning = {
      configuration = {
        type = var.defender_server_va_auto_provisioning_plan
      }
      enabled = true
    }
  }

  //defender_for_containers
  defender_containers_gcp = {
    offeringType                  = "DefenderForContainersGcp"
    auditLogsAutoProvisioningFlag = var.defenders_for_containers_auto_provisioning_logs,
    dataPipelineNativeCloudConnection = {
      serviceAccountEmailAddress = "${var.defenders_for_containers_data_pipeline_service_account_name}${local.gcp_service_account_email}"
      workloadIdentityProviderId = var.defenders_for_containers_data_pipeline_workload_identity_provider_id
    }
    defenderAgentAutoProvisioningFlag = var.defender_for_containers_auto_provisioning,
    nativeCloudConnection = {
      serviceAccountEmailAddress = "${var.defenders_containers_gcp_service_name}${local.gcp_service_account_email}"
      workloadIdentityProviderId = var.defenders_for_containers_workload_identity_provider_id
    }
    policyAgentAutoProvisioningFlag = var.defender_containers_policy_agent_auto_provisioning
  }

  //defender for databases
  defender_db_gcp = {
    offeringType = "DefenderForDatabasesGcp"
    arcAutoProvisioning = {
      configuration = {}
      enabled       = true
    }
    defenderForDatabasesArcAutoProvisioning = {
      serviceAccountEmailAddress = "${var.defender_db_gcp_service_account_name}${local.gcp_service_account_email}"
      workloadIdentityProviderId = var.defenders_db_workload_identity_provider_id
    }
  }

  //security connector offerings for AWS and GCP
  security_connector_gcp_offerings = [local.cspm_gcp, local.defender_cspm_gcp, local.defender_containers_gcp, local.defender_db_gcp, local.defender_servers_gcp]
  //filtering the offerings based on the offerings selected in the variable
  security_connector_gcp_offerings_filtered = [for offering in local.security_connector_gcp_offerings : offering if contains(var.mdc_offerings, trimsuffix(offering.offeringType, "Gcp"))]


}

resource "azapi_resource" "mdc_azure_security_connector_gcp" {
  schema_validation_enabled = false
  type                      = "Microsoft.Security/securityConnectors@2022-08-01-preview"
  name                      = var.connector_name
  location                  = var.mdc_azure_resource_group_location
  parent_id                 = var.mdc_azure_resource_group_id
  tags                      = var.mdc_connector_tags

  body = jsonencode({
    properties = {
      environmentData = {
        environmentType = "GcpProject"
        projectDetails = {
          projectId     = var.project_name
          projectNumber = var.project_number
        }
      },
      environmentName     = "GCP",
      hierarchyIdentifier = var.project_number,
      offerings           = local.security_connector_gcp_offerings_filtered
    }
  })
}