# Protect Azure VM Backup from Ransomware Attacks

**Author(s)**: Akhil Nampelly & Vasavi Pasula

**Contributor(s)**: Srinath Vasireddy, Chaya Aishwarya

In the event of a malware or a ransomware attack on an Azure Virtual Machine, Microsoft Defender for Cloud detects suspicious activity and indicators associated with ransomware on an Azure VM and generates a Security Alert. Perform regular backup is the best way to protect your data against Ransomware and hence ensure business continuity.   

The logic app deployed using this template will prevent the loss of recovery points of Azure VMs in the event of a Security Alert raised by Defender for Cloud by disabling the backup policy (by performing Stop Backup and Retain Data) against the backup item. This will ensure that the recovery points don’t expire based on schedule and are hence available for clean recovery. Upon the completion of this operation on the backup item, the Backup admin is automatically notified about the same over email. The alert can then be manually triaged in coordination with the Security admin and backups can be resumed once the issue in the source VM is resolved or if it’s a false alarm.  

**Scope:**

The logic app can be deployed at a subscription level, which means that all Azure VMs under the subscription can leverage the logic app for pausing backup pruning in the event of a security alert for Ransomware detection.
The ARM template will create the Logic App Playbook and an API connection to Office 365, and ASCalert. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the Subscription.

 
**Create a User Assigned Managed Identity**
To create a user-assigned managed identity, your account needs the Managed Identity Contributor role assignment. 

Sign in to the Azure portal. 

1. In the search box, enter Managed Identities. Under Services, select Managed Identities. 
2. Select Add, and enter values in the following boxes in the Create User Assigned Managed Identity pane: 
3. Subscription: Choose the subscription to create the user-assigned managed identity under. 
4. Resource group: Choose a resource group to create the user-assigned managed identity in, or select Create new to create a new resource group. 
5. Region: Choose a region to deploy the user-assigned managed identity, for example, West US. 
6. Name: Enter the name for your user-assigned managed identity, for example, UAI1. 
7. Select Review + create to review the changes. 
8. Select Create. 


**Deploy the template by clicking the respective button below.**

<a href="https://aka.ms/ProtectBackupfromRansomware" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>

The Logic App uses a user-assigned Managed Identity. You need to assign 'Security Reader' and 'Virtual Machine Contributor', 'Backup Contributor'  permissions to the Logic App's Managed Identity so it is able to perform the Disable Backup Policy operation on the backup automatically in the event of a Ransomware alert. You need to assign these roles on all subscriptions or management groups you want to monitor and manage resources in using this playbook. Notice that you can assign permissions only if your account has been assigned Owner or User Access Administrator roles, and make sure all selected subscriptions registered to Microsoft Defender for Cloud.

You need to authorize the Office 365 API connection so it can access the sender mailbox and send the emails from there.

**To assign Managed Identity to specific scope:**

1. Make sure you have User Access Administrator or Owner permissions for this scope.
2. Go to the subscription/management group page (by searching for Subscriptions in the searchbar in the Azure portal).
3. Go to Access Control (IAM) on the navigation bar.
4. Press +Add and Add role assignment.
5. In Check access, go to Add role assignment.
6. Select the 'VM Contributor' , 'Backup Contributor', and 'Security Reader' Roles.
7. Click on the Assignments tab, and seach for the name of your logic app.
8. Assign access to Logic App.
9. Select the subscription where the logic app was deployed.
10.Select "Protect-Azure-VM-Backup-from-Ransomware" Logic App.
11.Press save.

**To authorize the API connection:**

1. Go to the Resource Group you have used to deployed the template resources.
2. Select the Office365 API connection (which is one of the resources you just deployed) and click on the error that appears at the API connection.
3. Press Edit API connection.
4. Press the Authorize button.
5. Make sure to authenticate against Azure AD.
6. Press save.

**Once you have deployed and authorized the Logic App, you can create a new Workflow automation in Microsoft Defender for Cloud**

1. Go to Microsoft Defender for Cloud and select the Workflow automation button in the navigation pane.
2. Select + Add workflow automation.
3. Enter the values needed. Especially make sure you select Threat detection alerts as the trigger condition.
4. In the Alert name contains field, enter "Ransomware".
5. In the actions area, make sure to select the Protect-Azure-VM-Backup-from-Ransomware Logic App you have deployed and authorized before.
6. Press create.
