variable "mgmt_group_name" {
  type        = string
  description = "Specifies the name or UUID of this Management Group."
  default     = "[YourManagmentGroupName]" // Change this to your management group ID
}
variable "scope" {
  type = string
  description = "Specifies the scope of application of policy and remediation"
  default = "/providers/Microsoft.Management/managementGroups/[YourManagmentGroupName]" //Change this to your desired scope
}
variable "resource_group_name" {
  type        = string
  description = "Specifies the name of this Resource Group."
  default = "[YourResourceGroupName]" //Add your ResourceGroupName
}
variable "location" {
  type        = string
  description = "Specifies the Azure location where the Resource Group should exist."
  default = "eastus" //Change location as needed
}
variable "email" {
  type = string
  description = "Email of the Contact for Security Alerts in Defender for Cloud"
  default = "email@yourdomain.com" //Email distro for Microsoft Defender for Cloud alerts
}
variable "phonenumber" {
  type = string
  description = "Phone Contact for Security alerts"
  default = "123456789" //Phone number contact for alerts. 
}