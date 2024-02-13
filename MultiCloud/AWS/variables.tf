variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "aad_tenant_id" {
  description = "Tenant ID of AAD tenant containing Microsoft Defender for Cloud applications"
  type        = string
  default     = "33e01921-4d64-4f8c-a055-5bdaffd5e33d"
}

variable "least_privilege_permissions" {
  description = "Permissions type allowed for Microsoft defender for cloud"
  type        = bool
  default     = false
}

variable "oidc_client_id_list" {
  description = "List of Client IDs (app ids) that can authenticate to the OIDC provider"
  type        = list(string)
  default     = ["api://4d8bed1f-eee7-4d8e-b0dc-8462049a4479", "api://AzureSecurityCenter.MultiCloud.DefenderForServers", "api://AzureSecurityCenter.MultiCloud.DefenderForDatabases", "api://b2f86835-c959-461c-b08c-2cd5ca382af5", "api://6610e979-c931-41ec-adc7-b9920c9d52f1", "api://AzureSecurityCenter.MultiCloud.DefenderForServers.VmScanner"]
}

variable "oidc_thumbprint_list" {
  description = "Thumbprint of OIDC providers server certificate"
  type        = list(string)
  default     = ["626d44e704d1ceabe3bf0d53397464ac8080142c"]
}

variable "CspmMonitorAwsIamRoleName" {
  description = "Provide a role ARN name CspmIamRole for needed offerings"
  type        = string
  default     = "CspmMonitorAws"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.CspmMonitorAwsIamRoleName))
    error_message = "CspmMonitorAwsIamRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "ArcAutoProvisioningRoleName" {
  description = "Provide a role ARN name DefenderForCloud-ArcAutoProvisioning for needed offerings"
  type        = string
  default     = "DefenderForCloud-ArcAutoProvisioning"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.ArcAutoProvisioningRoleName))
    error_message = "ArcAutoProvisioningRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "DefenderForServersRoleName" {
  description = "role ARN name DefenderForCloud-DefenderForServers for Servers offering"
  type        = string
  default     = "DefenderForCloud-DefenderForServers"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.DefenderForServersRoleName))
    error_message = "DefenderForServersRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "DefenderForServersVmScannerRoleName" {
  description = "role ARN name DefenderForCloud-AgentlessScanner for Servers offering"
  type        = string
  default     = "DefenderForCloud-AgentlessScanner"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.DefenderForServersVmScannerRoleName))
    error_message = "DefenderForServersVmScannerRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "SecurityCenterKubernetesRoleName" {
  description = "role ARN name DefenderForCloud-Containers-K8s for containers offering"
  type        = string
  default     = "DefenderForCloud-Containers-K8s"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.SecurityCenterKubernetesRoleName))
    error_message = "SecurityCenterKubernetesRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "DefenderForCloudContainersK8sKinesisToS3RoleName" {
  description = "role ARN name DefenderForCloud-Containers-K8s-kinesis-to-s3 for containers offering"
  type        = string
  default     = "DefenderForCloud-Containers-K8s-kinesis-to-s3"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.DefenderForCloudContainersK8sKinesisToS3RoleName))
    error_message = "DefenderForCloudContainersK8sKinesisToS3RoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "AzureDefenderKubernetesScubaReaderRoleName" {
  description = "role ARN name container vulnerability assessment for containers offering"
  type        = string
  default     = "DefenderForCloud-DataCollection"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.AzureDefenderKubernetesScubaReaderRoleName))
    error_message = "AzureDefenderKubernetesScubaReaderRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "AzureDefenderKubernetesScubaReaderRoleStsExternalId" {
  description = "Sts external id for azure defender kuberenetes scuba reader role"
  type        = string
  default     = "b6d36db8-eda7-4617-9d4f-41149b899dc7"
}

variable "AzureDefenderCloudWatchToKinesisRoleName" {
  description = "role ARN name DefenderForCloud-Containers-K8s-cloudwatch-to-kinesis for containers offering"
  type        = string
  default     = "DefenderForCloud-Containers-K8s-cloudwatch-to-kinesis"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.AzureDefenderCloudWatchToKinesisRoleName))
    error_message = "AzureDefenderCloudWatchToKinesisRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "MDCContainersAgentlessDiscoveryK8sRoleName" {
  description = "role ARN name MDCContainersAgentlessDiscoveryK8sRole for Containers offering"
  type        = string
  default     = "MDCContainersAgentlessDiscoveryK8sRole"
  validation {
    condition     = can(regex("(MDC)[-_a-zA-Z0-9]+", var.MDCContainersAgentlessDiscoveryK8sRoleName))
    error_message = "MDCContainersAgentlessDiscoveryK8sRoleName can only contain alphanumeric characters and hyphens and starts with MDC prefix."
  }
}

variable "MDCContainersImageAssessmentRoleName" {
  description = "role ARN name MDCContainersImageAssessmentRole for Containers offering"
  type        = string
  default     = "MDCContainersImageAssessmentRole"
  validation {
    condition     = can(regex("(MDC)[-_a-zA-Z0-9]+", var.MDCContainersImageAssessmentRoleName))
    error_message = "MDCContainersImageAssessmentRoleName can only contain alphanumeric characters and hyphens and starts with MDC prefix."
  }
}

variable "SensitiveDataDiscoveryRoleName" {
  description = "role ARN name SensitiveDataDiscovery for Database offering"
  type        = string
  default     = "SensitiveDataDiscovery"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.SensitiveDataDiscoveryRoleName))
    error_message = "SensitiveDataDiscoveryRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "DataSecurityPostureDbRoleName" {
  description = "Provide a role ARN name DefenderForCloud-DataSecurityPostureDB for Databases DSPM offering"
  type        = string
  default     = "DefenderForCloud-DataSecurityPostureDB"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.DataSecurityPostureDbRoleName))
    error_message = "DataSecurityPostureDbRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "CiemOidcRoleName" {
  description = "Provide an role name for CIEM offering OIDC role"
  type        = string
  default     = "DefenderForCloud-OidcCiem"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.CiemOidcRoleName))
    error_message = "CiemOidcRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "CiemAccountRoleName" {
  description = "Provide an role name for CIEM offering Account role"
  type        = string
  default     = "DefenderForCloud-Ciem"
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.CiemAccountRoleName))
    error_message = "CiemAccountRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "AzureSPClientId" {
  description = "Service Principal Client Id"
  type        = string
  default     = "f819bf1c-9cf9-42c3-bd59-82c507565fa1"
}

variable "CiemCloudTrailBucketName" {
  description = "The name of the s3 bucket where cloudtrail logs are stored"
  type        = string
  default     = "*"
}

variable "ConfigurationID" {
  description = "(Required) Unique identifier of the deployed configuration."
  type        = string
  default     = "MDCSetup"
}

variable "IsPolicyAttachAllowed" {
  description = "(Optional) Whether Microsoft Defender for Cloud setup is allowed to attach policies to existing Instance profiles"
  type        = bool
  default     = true
}

variable "SetupType" {
  description = "(Required) Specifies the type of the Setup: either Local or Organizational."
  type        = string
  default     = "Organizational"
  validation {
    condition     = can(regex("^(Organizational|Local)$", var.SetupType))
    error_message = "SetupType can only be Organizational or Local."
  }
}

variable "TargetType" {
  description = "(Optional) Specifies the way in which instances are targeted - applies only for local MDCSetup."
  type        = string
  default     = "*"
  validation {
    condition     = can(regex("^(Tags|InstanceIds|[=*=]|ResourceGroups)$", var.TargetType))
    error_message = "TargetType can only be Tags, InstanceIds, ResourceGroups or *."
  }
}

variable "TargetTagKey" {
  description = "(Optional) Specifies the tag key of instances to be targeted when SetupType=Local and TargetType=Tags"
  type        = string
  default     = ""
}

variable "TargetTagValue" {
  description = "(Optional) Specifies the tag value of instances to be targeted when SetupType=Local and TargetType=Tags"
  type        = string
  default     = ""
}

variable "ResourceGroupName" {
  description = "(Optional) Specifies the resource group name to be targeted when SetupType=Local and TargetType=ResourceGroups"
  type        = string
  default     = ""
}

variable "TargetInstances" {
  description = "(Optional) Specifies the instance ids of instances to be targeted when SetupType=Local and TargetType=InstanceIds"
  type        = string
  default     = "*"
}

variable "ProvidedInstanceProfileName" {
  description = "(Optional) Specifies the instance profile Name provided by the user when SetupType=Local."
  type        = string
  default     = ""
}

variable "ProvidedAssumeRoleArn" {
  description = "(Optional) Specifies the automation assume role Arn provided by the user when SetupType=Local."
  type        = string
  default     = "*"
}

variable "client_tenant" {
  description = "Client tenant id"
  type        = string
}