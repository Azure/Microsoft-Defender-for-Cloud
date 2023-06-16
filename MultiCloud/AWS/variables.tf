variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "aad_tenant_id" {
  description = "Tenant ID of AAD tenant containing MDC applications"
  default     = "33e01921-4d64-4f8c-a055-5bdaffd5e33d"
}

variable "offerings" {
  description = "List of offering to enable for the AWS account"
  type        = list(string)
  default     = ["DefenderCspm", "DefenderForContainers", "DefenderForDatabases", "DefenderForServers"]
}

variable "oidc_client_id_list" {
  description = "List of Client IDs (app ids) that can authenticate to the OIDC provider"
  default = [
    "api://4d8bed1f-eee7-4d8e-b0dc-8462049a4479",
    "api://AzureSecurityCenter.MultiCloud.DefenderForServers",
    "api://AzureSecurityCenter.MultiCloud.DefenderForServers.VmScanner"
  ]
}

variable "oidc_thumbprint_list" {
  description = "Thumbprint of OIDC providers server certificate"
  default     = ["626d44e704d1ceabe3bf0d53397464ac8080142c"]
}

variable "ArcAutoProvisioningRoleName" {
  type        = string
  description = "Provide a role ARN name DefenderForCloud-ArcAutoProvisioning for needed offerings"
  default     = "DefenderForCloud-ArcAutoProvisioning"

  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.ArcAutoProvisioningRoleName))
    error_message = "ArcAutoProvisioningRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "DefenderForServersRoleName" {
  description = "role ARN name DefenderForCloud-DefenderForServers for Servers offering"
  default     = "DefenderForCloud-DefenderForServers"
  type        = string
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.DefenderForServersRoleName))
    error_message = "DefenderForServersRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "DefenderForServersVmScannerRoleName" {
  description = "role ARN name DefenderForCloud-AgentlessScanner for Servers offering"
  default     = "DefenderForCloud-AgentlessScanner"
  type        = string
  validation {
    condition     = can(regex("[-_a-zA-Z0-9]+", var.DefenderForServersVmScannerRoleName))
    error_message = "DefenderForServersVmScannerRoleName can only contain alphanumeric characters and hyphens."
  }
}

variable "ConfigurationID" {
  description = "(Required) Unique identifier of the deployed configuration."
  default     = "MDCSetup"
  type        = string
}

variable "IsPolicyAttachAllowed" {
  type        = bool
  default     = true
  description = "(Optional) Whether MDc setup is allowed to attach policies to existing Instance profiles"
}

variable "SetupType" {
  type        = string
  default     = "Organizational"
  description = "(Required) Specifies the type of the Setup: either Local or Organizational."

  validation {
    condition     = can(regex("^(Organizational|Local)$", var.SetupType))
    error_message = "SetupType can only be Organizational or Local."
  }
}

variable "TargetType" {
  type        = string
  default     = "*"
  description = "(Optional) Specifies the way in which instances are targeted - applies only for local MDCSetup."

  validation {
    condition     = can(regex("^(Tags|InstanceIds|[=*=]|ResourceGroups)$", var.TargetType))
    error_message = "TargetType can only be Tags, InstanceIds, ResourceGroups or *."
  }
}

variable "TargetTagKey" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the tag key of instances to be targeted when SetupType=Local and TargetType=Tags"
}

variable "TargetTagValue" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the tag value of instances to be targeted when SetupType=Local and TargetType=Tags"
}

variable "ResourceGroupName" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the resource group name to be targeted when SetupType=Local and TargetType=ResourceGroups"
}

variable "TargetInstances" {
  type        = string
  default     = "*"
  description = "(Optional) Specifies the instance ids of instances to be targeted when SetupType=Local and TargetType=InstanceIds"
}

variable "ProvidedInstanceProfileName" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the instance profile Name provided by the user when SetupType=Local."
}

variable "ProvidedAssumeRoleArn" {
  type        = string
  default     = "*"
  description = "(Optional) Specifies the automation assume role Arn provided by the user when SetupType=Local."
}
