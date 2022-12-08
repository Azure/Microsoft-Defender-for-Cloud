# Audit disk encryption compliance on Linux VMs

This is an auditIfNotExists policy for auditing disk encryption compliance on Linux VMs. This is the new version of the MDC recommendation for monitoring disk encryption compliance. In the new version, VMs which are encrypted with Azure Disk Encryption (ADE) or Host Based Encryption (HBE) will be reported as compliant.


The policy leverages the Azure Guest Configuration service to perform assessments within the VM. Pre-requisites listed below need to be installed before enabling the policy.

##### Pre-Requisites for Guest Configuration service:
1. Install the Guest Configuration extension for Linux on the VM. See the article [here](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/guest-configuration) for instructions.
2. Enabled System Assigned Managed Identity on the VM. See the article [here](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm) for instructions.

##### Examples of non-compliant VMs:
		-VMs not encrypted with ADE or HBE.
		-VMs that are partially encrypted with ADE i.e. OS disk is encrypted but data disks are unencrypted or vice versa.

##### Unsupported scenarios for ADE and HBE:
		-Azure Arc Machines are currently not supported by ADE and HBE.
		-VMs already encrypted with SSE + CMK (Server-side encryption with Customer Managed Keys) cannot be re-encrypted using ADE.

## Try on Portal

1. Click on the 'DeployToAzure' button below to redirect to Azure portal.
2. Paste the JSON from 'policy.json' file in the 'Policy Rule' section on Azure portal.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/)