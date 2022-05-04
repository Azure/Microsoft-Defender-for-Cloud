# Audit disk encryption on Windows VMs only (v2)

Purpose: 
	- The attached policy template is a custom auditIfNotExists policy to monitor Windows VMs for disk encryption compliance. This is the new version of ASC recommendation for Azure Disk Encryption.
	- The new version incorporates the use of the Guest Configuration extension to check for disk encryption compliance. 
	- In the new version, VMs which are encrypted with Azure Disk Encryption (ADE) or Host Based Encryption (HBE) will be reported as compliant.

Examples of non-compliant VMs:
	- VMs not encrypted with ADE or HBE.
	- VMs that are encrypted with ADE but the extension has been uninstalled from the VM.
	
Instructions to use policy:
	Pre-Requisites for Guest Configuration service:
		- Install the Guest Configuration extension for Windows on the VM.
		- Enabled System Assigned Managed Identity on the VM.
	
	Create a custom Azure policy through the portal:
		- For policy category, choose 'Use Existing' and select 'Guest Configuration' from the list. 
		- Use the file 'policy.json' as the policy definition. 
		
	Assign the policy to a subscription/resource group and monitor VMs for encryption compliance status. 

	

