# Microsoft Defender for Cloud - Define Trusted IPs

| Version | Description | Author | Date |
| ------ | ------ | ------ | ------ |
| 1.0 | Initial release | [Luke Pan](https://github.com/lukepan2024)| 06/20/2025|

### Description

The Trusted Exposure preview feature in Microsoft Defender for Cloud allows organizations to define specific IP address ranges as "trusted," ensuring that resources accessible only from these IPs are not flagged as internet-exposed risks.
This helps reduce false positives in security alerts and improves the accuracy of attack path analysis. Use the provided policy definition to define these trusted IP ranges across management groups and subscriptions.

### Usage

The simplest way to deploy this Policy definition is by clicking on the "Deploy To Azure" button below. It will take you to the Azure Portal where you'll create a Template Deployment out of the [azuredeploy.json](./azuredeploy.json) ARM template.
  
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FPolicy%2FDefine%20MDC%20Trusted%20IPs%2Fazuredeploy.json)

Once deployed, you can assign the **Deploy Microsoft Defender for Cloud Trusted IPs** policy definition at the desired scope, then fill in the required parameters:

* IP Address Ranges - The list of trusted IP Address ranges in CIDR Notation
* Resource Group Region - The region where the resource group and ipGroup should be deployed
### Step-by-Step: Configure Trusted IPs using Azure Policy

1. **Access Azure Policy in the Portal**

   - Sign in to the [Azure Portal](https://portal.azure.com/).
   
   - Navigate to **Policy** in the left sidebar.
   
1. **Locate or Create Trusted IP Policy**

- Search for the policy named **Define MDC Trusted IPs** or use the [policy definition from GitHub](https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Policy/Define%20MDC%20Trusted%20IPs).

   - If not available, click **Definitions** > **+ Policy definition** and paste the required JSON that defines the trusted IPs and CIDRs.
   
1. **Assign the Policy**

- Click **Assignments** > **+ Assign policy**.

- Select **Scope** (choose the subscription or management group).

   - Choose the **Trusted IPs policy** you created or located.
   
1. **Configure Parameters**

- In the **Parameters** section, enter the trusted CIDR ranges or IP addresses you want to allow.

   - Save and review the assignment.
   
1. **Monitor Compliance**

   - Go to the **Compliance** tab under Policy to monitor resources for compliance with the Trusted IPs policy.
   
**Review Defender for Cloud Insights**

   - Defender for Cloud will automatically read the policy and apply it to supported resources.
   
   - You’ll see new “Trusted Exposure” insights in the Cloud Security Explorer, indicating which resources are only exposed to your trusted IPs.
   
