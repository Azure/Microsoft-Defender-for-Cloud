# VM Extension Management
For optimal security monitoring of your Virtual Machines (VM's) in Azure, Security Center requires the MMA VM Extension.<br>
The two PowerShell sample scripts will get *all* your VMs in *all* your subscriptions, create an output file which you can use to review the MMA extension installation status.<br>
The second sample script will allow you to import the reviewed and edited CSV file. This file will be used to install the MMA VM Extension on the VMs in the input file.

Script details:<br>
**Check-MMA-VMExtension.ps1**
1. Enumerate all the VMs in all your subscriptions for which you have access to
2. Export the list of VMs to a CSV formatted file, containing metadata (VMname, Extension installed yes/no, SubscriptionName, SubscriptionID, ResourceGroup, etc.)
<br><br>

**Install-MMA-VMExtension.ps1**
1. Import a reviewed and edited CSV list, containing VM's for which you want to install the VM extension
2. Install the VM extension on each and every VM in the input file, enumerating through your subscriptions
<br><br>

#### Prerequisites
For the PowerShell script to run successfully you need to make sure that:
1. You have installed the Az PowerShell module
2. You are logged into Azure with PowerShell (Login-AzAccount)
3. You have the appropriate permissions and access to your subscriptions and VMs to enumerate and install the VM extension

#### Support
Although these PowerShell scripts are using the official and supported PowerShell modules for Azure, the script itself is **unsupported**.<br>
Please test thoroughly before using in production.
