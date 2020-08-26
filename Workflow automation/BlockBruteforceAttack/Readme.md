# Block the IPs in NSG as response to a brute-force attack when an ASC alert is triggered/created
**Author: Safeena Begum**

When Azure Security Center detects a Bruteforce attack, it creates a security rule in the NSG attached to the VM to deny inbound traffic from the IP addresses attached to the alert. 

The ARM template will create the LogicApp Playbook and an API connection to Office 365, and ASCalert. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group.

The LogicApp uses a system-assigned Managed Identity. You need to assign [security reader](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security-reader) permissions and [contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) or [Network Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) permissions (for the logicapp to be able to create an NSG rule when there’s an attack detected) to subscriptions you want to export for the Managed Identity (explained in detail below). Notice you can assign permissions only as an owner and make sure all selected subscriptions registered to Azure Security Center. 

In addition to that, you need to authorize the Office 365 API connection so it can access the sender mailbox and send the emails from there. 
