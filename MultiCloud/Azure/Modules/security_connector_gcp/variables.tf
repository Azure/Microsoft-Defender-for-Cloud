variable "project_name" {
  type        = string
  description = "GCP project name"
}

variable "project_number" {
  type        = string
  description = "GCP project number"
}

variable "connector_name" {
  type        = string
  description = "name of the base connector, account/project name will be appended to this name."
}

variable "mdc_azure_resource_group_id" {
  type        = string
  description = "resource group name for MDC connectors"
}

variable "mdc_azure_resource_group_location" {
  type        = string
  description = "resource group location for MDC connectors"
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
variable "cspm_gcp_service_account_name" {
  type        = string
  description = "GCP service account name for CSPM"
  default     = "microsoft-defender-cspm"
}

variable "cspm_gcp_workload_identity_provider_id" {
  type        = string
  description = "workload identity provider ID for CSPM"
  default     = "cspm"
}


// Defender for servers
variable "defender_servers_gcp_service_account_name" {
  type        = string
  description = "GCP service account name for Defender for Servers"
  default     = "microsoft-defender-for-servers"
}

variable "defender_servers_workload_identity_provider_id" {
  type        = string
  description = "workload identity provider ID for the defender for servers"
  default     = "defender-for-servers"
}

variable "defender_servers_sub_plan" {
  type        = string
  description = "Defender for servers subscription plan"
  default     = "P1"

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

// Defender for containers
variable "defenders_for_containers_auto_provisioning_logs" {
  type        = bool
  description = "Is audit logs data collection enabled"
  default     = true
}

variable "defenders_for_containers_data_pipeline_service_account_name" {
  type        = string
  description = "GCP service account name for the data pipeline"
  default     = "ms-defender-containers-stream"
}

variable "defenders_for_containers_data_pipeline_workload_identity_provider_id" {
  type        = string
  description = "workload identity provider ID for the data pipeline"
  default     = "containers-streams"
}

variable "defender_for_containers_auto_provisioning" {
  type        = bool
  description = "auto provisioning for Defender for Containers"
  default     = true
}

variable "defenders_containers_gcp_service_name" {
  type        = string
  description = "GCP service account name for Defender for Containers"
  default     = "defender_for_containers"
}

variable "defenders_for_containers_workload_identity_provider_id" {
  type        = string
  description = "workload identity provider ID for the defender for containers"
  default     = "containers"
}

variable "defender_containers_policy_agent_auto_provisioning" {
  type        = bool
  description = "Is auto provisioning enabled for the policy agent"
  default     = true
}


// Defender for Databases
variable "defender_db_gcp_service_account_name" {
  type        = string
  description = "GCP service account name for Defender for Databases"
  default     = "microsoft-databases-arc-ap"
}

variable "defenders_db_workload_identity_provider_id" {
  type        = string
  description = "workload identity provider ID for the defender for databases"
  default     = "microsoft-databases-arc-ap"
}

