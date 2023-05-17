variable "mdc_azure_security_connector_name" {
  type        = string
  description = "name of the base connector, account/project name will be appended to this name."
  default     = "mdc_azure_security_connector"
}

variable "mdc_azure_resource_group_name" {
  type        = string
  description = "resource group name for MDC connectors"
}

variable "mdc_azure_resource_group_location" {
  type        = string
  description = "resource group location for MDC connectors"
}

variable "mdc_cloud_type" {
  type        = string
  default     = "AWS"
  description = "cloud type for MDC can be AWS or GCP."

  validation {
    condition     = can(regex("^(AWS|GCP)$", var.mdc_cloud_type))
    error_message = "mdc_cloud_type can only be AWS or GCP."
  }
}

variable "mdc_offerings" {
  type        = list(string)
  description = "Azure offerings for MDC"
  default     = ["CspmMonitor", "DefenderCspm", "DefenderForContainers", "DefenderForDatabases", "DefenderForServers"]
}

variable "account_id_or_project_number" {
  type        = list(string)
  description = "account IDs for AWS or project numbers for GCP for MDC connectors"
}

variable "gcp_project_names" {
  type        = list(string)
  description = "project names for GCP MDC connectors, should be ordered the same as account_id_or_project_number"

}

variable "mdc_connector_tags" {
  type        = map(string)
  description = "tags for the MDC connector"
  default = {
    "mdc_connector" = "true"
  }
}





