terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
      version = "1.2.0"
    }
  }
}

locals {
	arn_role_prefix = "arn:aws:iam::${var.account_id}:role/"

	//cspm monitor
	cspm_aws = {
	offeringType = "CspmMonitorAws"
	nativeCloudConnection = {
		cloudRoleArn = "${local.arn_role_prefix}${var.cspm_aws_role_arn}"
	}
}

  //defender cspm
  defender_cspm_aws = {
    offeringType = "DefenderCspmAws"
    vmScanners = {
      configuration = {
        cloudRoleArn  = "${local.arn_role_prefix}${var.defender_agenless_scanner_aws_role_arn}"
        exclusionTags = var.defender_aws_exclusion_tags
        scanningMode  = var.defender_cspm_aws_scanning_mode
      }
      enabled = true
    }
  }

	//defender for servers
	defender_servers_aws = {
		offeringType = "DefenderForServersAws"
		arcAutoProvisioning = {
			cloudRoleArn = "${local.arn_role_prefix}${var.defender_server_arc_auto_provisioning_arn_aws}"
			enabled      = true
      configuration = {}
		}
		defenderForServers = {
			cloudRoleArn = "${local.arn_role_prefix}${var.defender_server_arn_aws}"
		}
		mdeAutoProvisioning = {
      configuration = {}
			enabled = true
		}
		subPlan =  var.defender_servers_sub_plan
		vaAutoProvisioning = {
			configuration = {
				type = var.defender_server_va_auto_provisioning_plan
			}
			enabled = true
		}
		vmScanners = {
			configuration = {
				cloudRoleArn  = "${local.arn_role_prefix}${var.defender_agenless_scanner_aws_role_arn}"
				exclusionTags = var.defender_aws_exclusion_tags
				scanningMode  = var.defender_cspm_aws_scanning_mode
			}
			enabled = true
		}
	}

	  //defender for containers
  defender_containers_aws = {
    offeringType     = "DefenderForContainersAws"
    autoProvisioning = var.defender_for_containers_auto_provisioning
    cloudWatchToKinesis = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_cloudwatch_kinesis_aws_arn}"
    }
    containerVulnerabilityAssessment = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_container_va_aws_arn}"
    }
    containerVulnerabilityAssessmentTask = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_container_va_task_aws_arn}"
    }
    enableContainerVulnerabilityAssessment = var.enable_container_va_assessment
    kinesisToS3 = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_kinesis_to_s3_aws_arn}"
    }
    kubeAuditRetentionTime = var.defender_kube_audit_retention_time
    kubernetesScubaReader = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_kubernetes_scuba_reader_aws_arn}"
    }
    kubernetesService = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_kubernetes_aws_arn}"
    }
    scubaExternalId = var.defender_scuba_reader_external_id
  }

	 //defender for databases
  defender_db_aws = {
    offeringType = "DefenderForDatabasesAws"
    arcAutoProvisioning = {
      cloudRoleArn = "${local.arn_role_prefix}${var.defender_server_arc_auto_provisioning_arn_aws}"
      enabled      = true
      configuration = {}
    }
  }

	//security connector offerings filtered by mdc offerings
  security_connector_aws_offerings = [local.cspm_aws ,local.defender_cspm_aws, local.defender_containers_aws, local.defender_db_aws, local.defender_servers_aws]
	security_connector_aws_offerings_filtered = [for offering in local.security_connector_aws_offerings : offering if contains(var.mdc_offerings, trimsuffix(offering.offeringType, "Aws"))]

}

resource "azapi_resource" "mdc_azure_security_connector_aws" {
  schema_validation_enabled = false
  type      = "Microsoft.Security/securityConnectors@2022-08-01-preview"
  name      = var.connector_name_aws
  location  = var.mdc_azure_resource_group_location_aws
  parent_id = var.mdc_azure_resource_group_id_aws
  tags      = var.mdc_connector_tags_aws

  body = jsonencode({
    properties = {
      environmentData = {
        environmentType = "AwsAccount"
      }
      environmentName     = "AWS"
      hierarchyIdentifier = var.account_id
      offerings           = local.security_connector_aws_offerings_filtered
    }
  })
}
