#---------------------------------------------------------------------------------------------
# Script to Obtain MDE. VM Extension Base64Package and Deploy MDE VM Extension on a Single VM
#---------------------------------------------------------------------------------------------

#PRE REQs - ARMCLient, Azure CLI, Azure PowerShell

# Login in
Connect-AzAccount
armclient login

#Your AAD Tenant ID if your login is associated to many tenants
armclient token {YOUR AAD TENANT ID}

# URL to get the base 64 encoded package
$url1 = "https://management.azure.com/subscriptions/{SUBID}/providers/Microsoft.Security/mdeOnboardings?api-version=2021-10-01-preview"


# PUT Api to setup continuous export rule to send to Storage
armclient GET $url1

# URL and payload for MDE Onboard for a Single Windows Azure VM
$url2 = "https://management.azure.com/{RESOURCEID}/extensions/MDE.Windows?api-version=2015-06-15"

$payload2 = "{'name': 'MDE.Windows', 'id': '{RESOURCEID}/extensions/MDE.Windows', 'type': 'Microsoft.compute/virtualMachines/extensions', 'location': '{VMLOCATION}', 'properties': {'autoUpgradeMinorVersion': true, 'publisher': 'Microsoft.Azure.AzureDefenderForServers','type': 'MDE.Windows','typeHandlerVersion': '1.0','settings': {'azureResourceId': '{RESOURCEID}','vNextEnabled': 'true'},'protectedSettings': {'defenderForEndpointOnboardingScript': '{BASE64PACKAGE}'}}}"


# PUT Api to setup continuous export rule to send to Event Hubs
armclient PUT $url2 $payload2