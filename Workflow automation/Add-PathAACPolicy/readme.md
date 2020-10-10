> Add a new file path as allow list rule when an ASC alert is triggered/created for AAC policy
**Author: Lior Arviv**

Adaptive application controls are an intelligent and automated solution for defining allow lists of known-safe applications for your machines.
When you've enabled and configured adaptive application controls, you'll get security alerts if any application runs other than the ones you've defined as safe.
By using this Logic App automation, you can quickly respond to “Adaptive application control policy violation was audited” security alert.
The automation extracts a security alert and add the file path as a new allow list rule into the relevant VM/s group.

The ARM template will create the Logic App automation and the related API connection to Azure Security Center alert.
To be able to deploy the resources, your account needs to have Contributor rights on the target Resource Group.
The Logic App uses a System-Assigned Managed Identity.
To make this Logic App works, you can have two options: grant Security Admin built-in role to the Logic App's Managed Identity, or to create a custom role based on the principle of least privilege so it can read existing VMs group policy and modify them where needed without having high privileges as the Security Admin. You need to assign this role on all subscriptions or management groups you want to monitor and manage resources in using this Logic App.
To create the custom role: 
Notice that you can assign permissions only if your account has been assigned as Owner or User Access Administrator roles.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/" target="_blank">
<img src="http://aka.ms/deploytoazuregovbutton"/>
</a>
