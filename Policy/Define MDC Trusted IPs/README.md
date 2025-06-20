# Microsoft Defender for Cloud - Define Microsoft Defender for Cloud Trusted IPs

| Version | Description | Author | Date |
| ------ | ------ | ------ | ------ |
| 1.0 | Initial release | [Luke Pan](https://github.com/lukepan2024)| 06/20/2025|

## Description

The Trusted Exposure preview feature in Microsoft Defender for Cloud allows organizations to define specific IP address ranges as "trusted," ensuring that resources accessible only from these IPs are not flagged as internet-exposed risks.
This helps reduce false positives in security alerts and improves the accuracy of attack path analysis. Use the provided policy definition to define these trusted IP ranges across management groups and subscriptions.

## Usage

The simplest way to deploy this Policy definition is by clicking on the "Deploy To Azure" button below. It will take you to the Azure Portal where you'll create a Template Deployment out of the [azuredeploy.json](./azuredeploy.json) ARM template.
  
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FPolicy%2FDefine%20MDC%20Trusted%20IPs%2Fazuredeploy.json)

Once deployed, you can assign the **Define Microsoft Defender for Cloud Trusted IPs** policy definition at the desired scope, then fill in the required parameters:

* IP Address Ranges - The list of trusted IP Address ranges in CIDR Notation
* Resource Group Region - The region where the resource group and ipGroup should be deployed