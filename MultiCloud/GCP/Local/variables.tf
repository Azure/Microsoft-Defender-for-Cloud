variable "project_id" {
  description = "The ID of your project in GCP."
}

variable "workload_pool_id" {
  description = "ID for workload identity pool (customer MS tenant id)"
}

variable "offerings" {
  description = "List of offerings to enable for the AWS account"
  type        = list(string)
  default     = ["DefenderCspm", "DefenderForContainers", "DefenderForDatabases", "DefenderForServers"]
}

variable "enable_apis" {
  description = "Which APIs to enable for this project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "apikeys.googleapis.com",
    "cloudkms.googleapis.com"
  ]
}

variable "project_id_prefix" {
  description = "Project id prefix, org id is appended"
  default     = "mdc-mgmt-proj-"
}

variable "project_name" {
  description = "Default Project Name"
  default     = "MDC Management Project"
}

variable "mdc_tenant_id" {
  description = "MDC Tenenat ID"
  default     = "33e01921-4d64-4f8c-a055-5bdaffd5e33d"
}