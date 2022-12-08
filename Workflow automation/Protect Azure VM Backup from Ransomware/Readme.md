# Protect Azure VM Backup from Ransomware Attacks

**Deploy the template by clicking the respective button below.**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkflow%2520automation%2FStop-Protection-With-Retain-Data%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>

**Author(s)**: Akhil Nampelly & Vasavi Pasula

**Contributor(s)**: Srinath Vasireddy, Chaya Aishwarya

In the event of a malware or a ransomware attack on an Azure Virtual Machine, Microsoft Defender for Cloud detects suspicious activity and indicators associated with ransomware on an Azure VM and generates a Security Alert. Perform regular backup is the best way to protect your data against Ransomware and hence ensure business continuity.   

The logic app deployed using this template will prevent the loss of recovery points of Azure VMs in the event of a Security Alert raised by Defender for Cloud by disabling the backup policy (by performing Stop Backup and Retain Data) against the backup item. This will ensure that the recovery points don’t expire based on schedule and are hence available for clean recovery. Upon the completion of this operation on the backup item, the Backup admin is automatically notified about the same over email. The alert can then be manually triaged in coordination with the Security admin and backups can be resumed once the issue in the source VM is resolved or if it’s a false alarm.  

Note: This feature is currently supported only for Azure VMs.   

**Scope:**

The logic app can only be deployed at a subscription level, which means that all Azure VMs under the subscription can leverage the logic app for pausing backup pruning in the event of a security alert.
