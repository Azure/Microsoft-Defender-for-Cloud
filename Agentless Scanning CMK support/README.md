# Add CMK (Customer managed Keys) related permissions for agentless scanning Entra App Id

   This script iterate over all VMs in given subscriptions, flitering VMs with CMK (customer managed keys). It then shows all keyvaults connected to these VMs disks Disk Encryption Sets, and optionally 
   Sets permissions on this keyvaults to allow disk scanning app id to access them.
.PARAMETER Subscriptions
   An array of Azure Subscription IDs.
   
.PARAMETER Apply
   A switch parameter to control whether to apply Key Vault permissions.
.EXAMPLE
   .\AddCmkPermissions.ps1 -Subscriptions "Subscription1", "Subscription2" -Apply $true