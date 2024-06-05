
variable "location" {
  type        = string
  description = "Specifies the Azure location where the Resource Group should exist."
  default     = "eastus"
}

variable "email" {
  type        = string
  description = "Email of the Contact for Security Alerts in Defender for Cloud"
  default     = "email@yourdomain.com"
}
variable "phonenumber" {
  type        = string
  description = "Phone Contact for Security alerts"
  default     = "123456789"
}