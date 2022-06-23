# Audit disk encryption compliance on Windows VMs

This is an auditIfNotExists policy for auditing disk encryption compliance on Windows VMs. This is the new version of the MDC recommendation for monitoring disk encryption compliance. In the new version, VMs which are encrypted with Azure Disk Encryption (ADE) or Host Based Encryption (HBE) will be reported as compliant.


The policy leverages the Azure Guest Configuration service to perform assessments within the VM. Pre-requisites listed below need to be installed before enabling the policy.

##### Pre-Requisites for Guest Configuration service:
1. Install the Guest Configuration extension for Windows on the VM. See the article [here](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/guest-configuration) for instructions.
2. Enabled System Assigned Managed Identity on the VM. See the article [here](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm) for instructions.

##### Examples of non-compliant VMs:
		-VMs not encrypted with ADE or HBE.
		-VMs that are encrypted with ADE but the extension has been uninstalled from the VM.
	

## Try on Portal

While deploying policy definition, choose 'Guest Configuration' as the policy category.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FPolicy%2FAudit-WindowsVM-ADE-And-HBE%2Fpolicy.json)