variable "account_id" {
  type        = string
  description = "account ID for AWS"
}

variable "connector_name" {
  type        = string
  description = "name of the base connector, account/project name will be appended to this name."
}

variable "mdc_azure_resource_group_location" {
  type        = string
  description = "resource group location for MDC connectors"
}

variable "mdc_azure_resource_group_id" {
  type        = string
  description = "resource group id for MDC connectors"
}

variable "mdc_connector_tags" {
  type        = map(string)
  description = "tags for the MDC connector"
  default = {
    "mdc_connector" = "true"
  }
}

variable "mdc_offerings" {
  type        = list(string)
  description = "Azure offerings for MDC"
}

//csp monitor
variable "cspm_aws_role_arn" {
  type        = string
  description = "AWS role ARN for CSPM"
  default     = "CspmMonitorAws"
}

variable "defender_agenless_scanner_aws_role_arn" {
  type        = string
  description = "AWS role ARN for Defender CSPM"
  default     = "DefenderForCloud_AgentlessScanner"
}

variable "defender_aws_exclusion_tags" {
  type = object({
    key   = string
    value = string
  })
  description = "VM tags that indicates that VM should not be scanned"
  default = {
    key   = "DefenderCspmExclusion"
    value = "true"
  }
}

variable "defender_cspm_aws_scanning_mode" {
  type        = string
  description = "scanning mode for Defender CSPM"
  default     = "Default"
}

//defender for servers
variable "defender_server_arc_auto_provisioning_arn_aws" {
  type        = string
  description = "AWS role arn name for DefenderForServersArcAutoProvisioningRole"
  default     = "DefenderForCloud-ArcAutoProvisioning"
}

variable "defender_server_arn_aws" {
  type        = string
  description = "AWS role arn name for DefenderForServersRole"
  default     = "DefenderForCloud-DefenderForServers"
}

variable "defender_servers_sub_plan" {
  type        = string
  description = "Defender for servers subscription plan"
  default     = "P2"

  validation {
    condition     = contains(["P1", "P2"], var.defender_servers_sub_plan)
    error_message = "Defender for servers subscription plan can be only P1 or P2"
  }
}

variable "defender_server_va_auto_provisioning_plan" {
  type        = string
  description = "Defender for servers vulnerability assessment subscription plan"
  default     = "TVM"

  validation {
    condition     = contains(["TVM", "Qualys"], var.defender_server_va_auto_provisioning_plan)
    error_message = "Defender for servers vulnerability assessment subscription plan can be only TVM or Qualys"
  }
}

//defender for containers
variable "defender_for_containers_auto_provisioning" {
  type        = bool
  description = "auto provisioning for Defender for Containers"
  default     = true
}

variable "defender_cloudwatch_kinesis_aws_arn" {
  type        = string
  description = "AWS role arn name for AzureDefenderCloudWatchToKinesisRole"
  default     = "azuredefender_kubernetes_cloudwatch_to_kinesis"
}

variable "defender_container_va_aws_arn" {
  type        = string
  description = "AWS role arn name for AzureDefenderForContainersVaRole"
  default     = "azuredefender_containers_va"
}

variable "defender_container_va_task_aws_arn" {
  type        = string
  description = "AWS role arn name for AzureDefenderForContainersVaTaskRole"
  default     = "azuredefender_containers_va_task"
}

variable "defender_kinesis_to_s3_aws_arn" {
  type        = string
  description = "AWS role arn name for AzureDefenderKinesisToS3Role"
  default     = "azuredefender_kubernetes_kinesis_to_s3"
}

variable "defender_kubernetes_scuba_reader_aws_arn" {
  type        = string
  description = "AWS role arn name for AzureDefenderKubernetesScubaReaderRole"
  default     = "azuredefender_kubernetes_scuba_reader"
}

variable "defender_kubernetes_aws_arn" {
  type        = string
  description = "AWS role arn name for AzureDefenderKubernetesRole"
  default     = "azuredefender_kubernetes"
}

variable "defender_scuba_reader_external_id" {
  type        = string
  description = "The externalId used by the data reader to prevent the confused deputy attack"
  default     = "00d04923_b008_48fd_bc0e_faa7dfd0549e"
}

variable "defender_kube_audit_retention_time" {
  type        = number
  description = "The retention time for the kube audit logs in days"
  default     = 30
}

variable "enable_container_va_assessment" {
  type        = bool
  description = "Enable container vulnerability assessment"
  default     = true
}